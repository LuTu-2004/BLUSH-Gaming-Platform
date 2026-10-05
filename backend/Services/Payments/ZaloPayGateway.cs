using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Options;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Payments
{
    // Ví ZaloPay (API v2) - tài liệu: https://docs.zalopay.vn/v2/general/overview.html
    // Key sandbox lấy tại https://docs.zalopay.vn (mục Sandbox) hoặc đăng ký merchant.
    //
    // Luồng: backend gọi API tạo đơn -> nhận order_url -> người dùng trả tiền ->
    //   ZaloPay gọi callback (api/payment/zalopay/callback) khi thành công + chuyển trình duyệt về api/payment/zalopay/return
    public class ZaloPayGateway : IPaymentGateway
    {
        public const string ReturnPath = "api/payment/zalopay/return";
        public const string CallbackPath = "api/payment/zalopay/callback";

        private readonly HttpClient _http;
        private readonly ZaloPayOptions _options;
        private readonly string _publicBaseUrl;

        public ZaloPayGateway(HttpClient http, IOptions<PaymentOptions> options)
        {
            _http = http;
            _options = options.Value.ZaloPay;
            _publicBaseUrl = options.Value.PublicBaseUrl.TrimEnd('/');
        }

        public string Method => PaymentMethods.ZaloPay;

        public bool IsConfigured => _options.IsConfigured;

        // ZaloPay bắt buộc app_trans_id dạng yyMMdd_xxx (ngày giờ Việt Nam)
        private static string AppTransId(long orderCode) =>
            $"{DateTime.UtcNow.AddHours(7):yyMMdd}_{orderCode.ToString(CultureInfo.InvariantCulture)}";

        private static bool TryParseOrderCode(string? appTransId, out long orderCode)
        {
            orderCode = 0;
            var index = appTransId?.IndexOf('_') ?? -1;
            return index > 0 && long.TryParse(appTransId![(index + 1)..], out orderCode);
        }

        public async Task<GatewayCheckout> CreateAsync(GatewayOrder order)
        {
            var appTransId = AppTransId(order.OrderCode);
            var appTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString(CultureInfo.InvariantCulture);
            const string appUser = "BLUSH";
            const string item = "[]";
            var embedData = JsonSerializer.Serialize(new { redirecturl = $"{_publicBaseUrl}/{ReturnPath}" });
            var amount = order.Amount.ToString(CultureInfo.InvariantCulture);

            var mac = PaymentSignature.HmacSha256(_options.Key1, $"{_options.AppId}|{appTransId}|{appUser}|{amount}|{appTime}|{embedData}|{item}");
            var form = new Dictionary<string, string>
            {
                ["app_id"] = _options.AppId,
                ["app_trans_id"] = appTransId,
                ["app_user"] = appUser,
                ["app_time"] = appTime,
                ["amount"] = amount,
                ["item"] = item,
                ["embed_data"] = embedData,
                ["description"] = $"BLUSH - Thanh toan goi {order.PackageCode} #{order.OrderCode}",
                ["bank_code"] = "",
                ["callback_url"] = $"{_publicBaseUrl}/{CallbackPath}",
                ["mac"] = mac,
            };

            using var response = await _http.PostAsync(_options.Endpoint, new FormUrlEncodedContent(form));
            var body = await response.Content.ReadFromJsonAsync<ZaloCreateResponse>();
            if (body == null || body.ReturnCode != 1 || string.IsNullOrEmpty(body.OrderUrl))
            {
                throw new PaymentGatewayException($"ZaloPay từ chối tạo đơn: {body?.ReturnMessage ?? response.StatusCode.ToString()}");
            }
            return new GatewayCheckout { PaymentUrl = body.OrderUrl };
        }

        /// Callback server-to-server (chỉ gửi khi thành công). Sai chữ ký -> null.
        public GatewayResult? VerifyCallback(string data, string mac)
        {
            if (!IsConfigured) return null; // chưa có key thì chữ ký rỗng ai cũng tự tạo được -> không tin
            if (!PaymentSignature.AreEqual(PaymentSignature.HmacSha256(_options.Key2, data), mac)) return null;

            var payload = JsonSerializer.Deserialize<ZaloCallbackData>(data);
            if (payload == null || !TryParseOrderCode(payload.AppTransId, out var orderCode)) return null;
            return new GatewayResult(orderCode, true, payload.Amount, payload.ZpTransId.ToString(CultureInfo.InvariantCulture), null);
        }

        /// Trình duyệt quay về sau khi trả tiền (có checksum). Sai -> null.
        public GatewayResult? VerifyRedirect(IQueryCollection query)
        {
            if (!IsConfigured) return null; // chưa có key thì chữ ký rỗng ai cũng tự tạo được -> không tin
            string F(string key) => query[key].ToString();
            var raw = $"{F("appid")}|{F("apptransid")}|{F("pmcid")}|{F("bankcode")}|{F("amount")}|{F("discountamount")}|{F("status")}";
            if (!PaymentSignature.AreEqual(PaymentSignature.HmacSha256(_options.Key2, raw), F("checksum"))) return null;
            if (!TryParseOrderCode(F("apptransid"), out var orderCode)) return null;

            long.TryParse(F("amount"), out var amount);
            var success = F("status") == "1";
            return new GatewayResult(orderCode, success, amount, null, success ? null : "ZaloPay báo thanh toán không thành công");
        }

        private class ZaloCreateResponse
        {
            [JsonPropertyName("return_code")] public int ReturnCode { get; set; }
            [JsonPropertyName("return_message")] public string? ReturnMessage { get; set; }
            [JsonPropertyName("order_url")] public string? OrderUrl { get; set; }
        }

        private class ZaloCallbackData
        {
            [JsonPropertyName("app_trans_id")] public string? AppTransId { get; set; }
            [JsonPropertyName("amount")] public long Amount { get; set; }
            [JsonPropertyName("zp_trans_id")] public long ZpTransId { get; set; }
        }
    }
}
