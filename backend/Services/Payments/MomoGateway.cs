using System.Globalization;
using System.Text.Json.Serialization;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Options;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Payments
{
    // Ví MoMo (API v2, captureWallet) - tài liệu: https://developers.momo.vn/v3/docs/payment/api/wallet/onetime
    //   Tạo đơn:   POST {BaseUrl}/v2/gateway/api/create
    //   Truy vấn:  POST {BaseUrl}/v2/gateway/api/query
    //   BaseUrl: Production https://payment.momo.vn, Sandbox https://test-payment.momo.vn
    //
    // Luồng: backend gọi API tạo đơn -> nhận payUrl -> người dùng trả tiền trên trang/app MoMo ->
    //   MoMo gọi IPN (api/payment/momo/ipn) + chuyển trình duyệt về api/payment/momo/return.
    //   Nếu IPN không tới được (ngrok tắt...) thì app hỏi trạng thái -> backend gọi API truy vấn.
    public class MomoGateway : IPaymentGateway
    {
        public const string ReturnPath = "api/payment/momo/return";
        public const string IpnPath = "api/payment/momo/ipn";

        // orderId gửi MoMo phải duy nhất trên cả tài khoản đối tác -> thêm tiền tố để không trùng dự án khác dùng chung key test
        private const string OrderIdPrefix = "BLUSH";
        private const string RequestType = "captureWallet";

        // resultCode MoMo: 0 = thành công; 1000/7000/7002/9000 = đang xử lý; còn lại = thất bại (đã kết thúc)
        private static readonly HashSet<int> PendingCodes = new() { 1000, 7000, 7002, 9000 };

        private readonly HttpClient _http;
        private readonly MomoOptions _options;
        private readonly string _publicBaseUrl;
        private readonly string _baseUrl;

        public MomoGateway(HttpClient http, IOptions<PaymentOptions> options)
        {
            _http = http;
            _options = options.Value.Momo;
            _publicBaseUrl = options.Value.PublicBaseUrl.TrimEnd('/');
            _baseUrl = (_options.BaseUrl ?? (options.Value.IsProduction ? "https://payment.momo.vn" : "https://test-payment.momo.vn")).TrimEnd('/');
        }

        public string Method => PaymentMethods.MoMo;

        public bool IsConfigured => _options.IsConfigured;

        private static string OrderId(long orderCode) => OrderIdPrefix + orderCode.ToString(CultureInfo.InvariantCulture);

        public async Task<GatewayCheckout> CreateAsync(GatewayOrder order)
        {
            var orderId = OrderId(order.OrderCode);
            var orderInfo = $"Thanh toan goi {order.PackageCode} BLUSH";
            var redirectUrl = $"{_publicBaseUrl}/{ReturnPath}";
            var ipnUrl = $"{_publicBaseUrl}/{IpnPath}";
            const string extraData = "";

            // Thứ tự field trong chuỗi ký do MoMo quy định (theo bảng chữ cái)
            var raw = $"accessKey={_options.AccessKey}&amount={order.Amount}&extraData={extraData}&ipnUrl={ipnUrl}"
                + $"&orderId={orderId}&orderInfo={orderInfo}&partnerCode={_options.PartnerCode}"
                + $"&redirectUrl={redirectUrl}&requestId={orderId}&requestType={RequestType}";

            var request = new
            {
                partnerCode = _options.PartnerCode,
                requestId = orderId,
                amount = order.Amount,
                orderId,
                orderInfo,
                redirectUrl,
                ipnUrl,
                requestType = RequestType,
                extraData,
                lang = "vi",
                signature = PaymentSignature.HmacSha256(_options.SecretKey, raw),
            };

            using var response = await _http.PostAsJsonAsync($"{_baseUrl}/v2/gateway/api/create", request);
            var body = await response.Content.ReadFromJsonAsync<MomoResponse>();
            if (body == null || body.ResultCode != 0 || string.IsNullOrEmpty(body.PayUrl))
            {
                throw new PaymentGatewayException($"MoMo từ chối tạo đơn: {body?.Message ?? response.StatusCode.ToString()}");
            }
            return new GatewayCheckout { PaymentUrl = body.PayUrl };
        }

        public async Task<GatewayResult?> QueryAsync(long orderCode)
        {
            var orderId = OrderId(orderCode);
            var requestId = $"{orderId}-Q{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
            var raw = $"accessKey={_options.AccessKey}&orderId={orderId}&partnerCode={_options.PartnerCode}&requestId={requestId}";

            using var response = await _http.PostAsJsonAsync($"{_baseUrl}/v2/gateway/api/query", new
            {
                partnerCode = _options.PartnerCode,
                requestId,
                orderId,
                lang = "vi",
                signature = PaymentSignature.HmacSha256(_options.SecretKey, raw),
            });
            var body = await response.Content.ReadFromJsonAsync<MomoResponse>();
            if (body == null || PendingCodes.Contains(body.ResultCode)) return null;

            // Chỉ tin kết quả thuộc đúng đơn mình hỏi
            if (body.OrderId != orderId) return null;
            var success = body.ResultCode == 0;
            return new GatewayResult(orderCode, success, body.Amount, body.TransId?.ToString(CultureInfo.InvariantCulture), success ? null : body.Message);
        }

        /// Kiểm tra chữ ký dữ liệu MoMo gửi về (IPN dạng JSON và Return dạng query dùng chung bộ field). Sai -> null.
        public GatewayResult? Verify(IReadOnlyDictionary<string, string?> data)
        {
            if (!IsConfigured) return null; // chưa có key thì chữ ký rỗng ai cũng tự tạo được -> không tin
            string F(string key) => data.TryGetValue(key, out var v) ? v ?? string.Empty : string.Empty;

            var raw = $"accessKey={_options.AccessKey}&amount={F("amount")}&extraData={F("extraData")}&message={F("message")}"
                + $"&orderId={F("orderId")}&orderInfo={F("orderInfo")}&orderType={F("orderType")}&partnerCode={F("partnerCode")}"
                + $"&payType={F("payType")}&requestId={F("requestId")}&responseTime={F("responseTime")}"
                + $"&resultCode={F("resultCode")}&transId={F("transId")}";

            if (!PaymentSignature.AreEqual(PaymentSignature.HmacSha256(_options.SecretKey, raw), F("signature"))) return null;

            var orderId = F("orderId");
            if (!orderId.StartsWith(OrderIdPrefix) || !long.TryParse(orderId[OrderIdPrefix.Length..], out var orderCode)) return null;
            long.TryParse(F("amount"), out var amount);

            // Không đọc được mã, hoặc mã đang xử lý (VD 1000) -> chưa kết luận
            if (!int.TryParse(F("resultCode"), out var code) || PendingCodes.Contains(code)) return null;

            var success = code == 0;
            return new GatewayResult(orderCode, success, amount, F("transId"), success ? null : F("message"));
        }

        private class MomoResponse
        {
            [JsonPropertyName("resultCode")] public int ResultCode { get; set; }
            [JsonPropertyName("message")] public string? Message { get; set; }
            [JsonPropertyName("payUrl")] public string? PayUrl { get; set; }
            [JsonPropertyName("orderId")] public string? OrderId { get; set; }
            [JsonPropertyName("amount")] public long Amount { get; set; }
            [JsonPropertyName("transId")] public long? TransId { get; set; }
        }
    }
}
