using System.Globalization;
using System.Net;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Options;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Payments
{
    // VNPay (thẻ ATM nội địa, Visa/Master, QR VNPay) - tài liệu: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
    // Đăng ký sandbox miễn phí tại https://sandbox.vnpayment.vn/devreg/ để nhận TmnCode + HashSecret.
    //
    // Luồng: backend tạo link có chữ ký -> người dùng trả tiền trên web VNPay ->
    //   VNPay gọi IPN (api/payment/vnpay/ipn) báo kết quả + chuyển trình duyệt về api/payment/vnpay/return
    public class VnPayGateway : IPaymentGateway
    {
        public const string ReturnPath = "api/payment/vnpay/return";

        private readonly VnPayOptions _options;
        private readonly string _publicBaseUrl;

        public VnPayGateway(IOptions<PaymentOptions> options)
        {
            _options = options.Value.VnPay;
            _publicBaseUrl = options.Value.PublicBaseUrl.TrimEnd('/');
        }

        public string Method => PaymentMethods.VnPay;

        public bool IsConfigured => _options.IsConfigured;

        public Task<GatewayCheckout> CreateAsync(GatewayOrder order)
        {
            var vnNow = DateTime.UtcNow.AddHours(7);
            var parameters = new SortedDictionary<string, string>(StringComparer.Ordinal)
            {
                ["vnp_Version"] = "2.1.0",
                ["vnp_Command"] = "pay",
                ["vnp_TmnCode"] = _options.TmnCode,
                ["vnp_Amount"] = (order.Amount * 100).ToString(CultureInfo.InvariantCulture), // VNPay tính theo đơn vị x100
                ["vnp_CurrCode"] = "VND",
                ["vnp_TxnRef"] = order.OrderCode.ToString(CultureInfo.InvariantCulture),
                ["vnp_OrderInfo"] = $"Thanh toan goi {order.PackageCode} don {order.OrderCode}", // không dấu theo yêu cầu VNPay
                ["vnp_OrderType"] = "other",
                ["vnp_Locale"] = "vn",
                ["vnp_ReturnUrl"] = $"{_publicBaseUrl}/{ReturnPath}",
                ["vnp_IpAddr"] = order.ClientIp,
                ["vnp_CreateDate"] = vnNow.ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture),
                ["vnp_ExpireDate"] = order.ExpiresAtUtc.AddHours(7).ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture),
            };

            var query = BuildQuery(parameters);
            var signature = PaymentSignature.HmacSha512(_options.HashSecret, query);
            return Task.FromResult(new GatewayCheckout { PaymentUrl = $"{_options.PaymentUrl}?{query}&vnp_SecureHash={signature}" });
        }

        /// Kiểm tra chữ ký dữ liệu VNPay gửi về (IPN và Return dùng chung). Sai chữ ký -> null.
        public GatewayResult? Verify(IQueryCollection query)
        {
            if (!IsConfigured) return null; // chưa có key thì chữ ký rỗng ai cũng tự tạo được -> không tin
            var parameters = new SortedDictionary<string, string>(StringComparer.Ordinal);
            foreach (var (key, value) in query)
            {
                if (key.StartsWith("vnp_", StringComparison.Ordinal) && key != "vnp_SecureHash" && key != "vnp_SecureHashType" && !string.IsNullOrEmpty(value))
                {
                    parameters[key] = value.ToString();
                }
            }

            var expected = PaymentSignature.HmacSha512(_options.HashSecret, BuildQuery(parameters));
            if (!PaymentSignature.AreEqual(expected, query["vnp_SecureHash"])) return null;
            if (!long.TryParse(parameters.GetValueOrDefault("vnp_TxnRef"), out var orderCode)) return null;

            long.TryParse(parameters.GetValueOrDefault("vnp_Amount"), out var amountX100);
            var responseCode = parameters.GetValueOrDefault("vnp_ResponseCode");
            var success = responseCode == "00" && parameters.GetValueOrDefault("vnp_TransactionStatus") == "00";

            return new GatewayResult(
                orderCode,
                success,
                amountX100 / 100,
                parameters.GetValueOrDefault("vnp_TransactionNo"),
                success ? null : $"VNPay báo lỗi (mã {responseCode})");
        }

        // VNPay ký trên chuỗi key=value đã URL-encode, nối bằng '&', sắp xếp theo tên key
        private static string BuildQuery(SortedDictionary<string, string> parameters) =>
            string.Join("&", parameters.Select(kv => $"{WebUtility.UrlEncode(kv.Key)}={WebUtility.UrlEncode(kv.Value)}"));
    }
}
