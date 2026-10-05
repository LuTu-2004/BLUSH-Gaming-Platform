using System.Globalization;
using System.Text.Encodings.Web;
using System.Text.Json;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Options;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Payments
{
    // Chuyển khoản ngân hàng bằng mã VietQR.
    //
    // Sandbox/Production: đi qua PayOS (https://payos.vn/docs/api/) - tiền vào thẳng tài khoản ngân hàng của nhóm.
    //   Tạo link:   POST {PayOs.BaseUrl}/v2/payment-requests            -> mã QR + link trang thanh toán
    //   Truy vấn:   GET  {PayOs.BaseUrl}/v2/payment-requests/{orderCode}
    //   Hủy:        POST {PayOs.BaseUrl}/v2/payment-requests/{orderCode}/cancel
    //   Webhook:    PayOS POST về api/payment/payos/webhook khi tiền tới (khai báo URL này ở my.payos.vn)
    //   PayOS không có môi trường test: mỗi lần thử là chuyển tiền thật (thử với gói rẻ nhất).
    //
    // Mock: QR tĩnh tạo bởi img.vietqr.io (không tự xác nhận được, bấm nút giả lập trong app).
    public class VietQrGateway : IPaymentGateway
    {
        public const string WebhookPath = "api/payment/payos/webhook";
        public const string ReturnPath = "api/payment/payos/return";
        public const string CancelPath = "api/payment/payos/cancel";

        // PayOS: tài khoản ngân hàng không liên kết trực tiếp với PayOS chỉ cho mô tả tối đa 9 ký tự
        private const string Description = "BLUSH VIP";

        // Mã BIN -> tên ngân hàng để hiển thị (ngân hàng khác hiện mã BIN)
        private static readonly Dictionary<string, string> BankNames = new()
        {
            ["970422"] = "MB Bank", ["970436"] = "Vietcombank", ["970407"] = "Techcombank", ["970416"] = "ACB",
            ["970418"] = "BIDV", ["970415"] = "VietinBank", ["970423"] = "TPBank", ["970432"] = "VPBank",
            ["970448"] = "OCB", ["970403"] = "Sacombank", ["970405"] = "Agribank", ["970441"] = "VIB",
            ["970443"] = "SHB", ["970437"] = "HDBank", ["970454"] = "Viet Capital Bank", ["971011"] = "Viettel Money",
        };

        private static readonly JsonSerializerOptions JsStringify = new() { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };

        private readonly HttpClient _http;
        private readonly PaymentOptions _payment;
        private readonly PayOsOptions _payOs;
        private readonly VietQrOptions _static;

        public VietQrGateway(HttpClient http, IOptions<PaymentOptions> options)
        {
            _http = http;
            _payment = options.Value;
            _payOs = options.Value.PayOs;
            _static = options.Value.VietQr;
        }

        public string Method => PaymentMethods.VietQr;

        public bool IsConfigured => _payOs.IsConfigured;

        private bool UsePayOs => !_payment.IsMock && _payOs.IsConfigured;

        public static string StaticTransferContent(long orderCode) => $"BLUSH {orderCode}";

        public async Task<GatewayCheckout> CreateAsync(GatewayOrder order)
        {
            if (!UsePayOs) return CreateStatic(order);

            var baseUrl = _payment.PublicBaseUrl.TrimEnd('/');
            var returnUrl = $"{baseUrl}/{ReturnPath}";
            var cancelUrl = $"{baseUrl}/{CancelPath}";
            var orderCode = order.OrderCode.ToString(CultureInfo.InvariantCulture);
            var amount = order.Amount.ToString(CultureInfo.InvariantCulture);

            // Chữ ký: các field sắp theo bảng chữ cái
            var raw = $"amount={amount}&cancelUrl={cancelUrl}&description={Description}&orderCode={orderCode}&returnUrl={returnUrl}";
            using var request = NewRequest(HttpMethod.Post, "/v2/payment-requests");
            request.Content = JsonContent.Create(new
            {
                orderCode = order.OrderCode,
                amount = order.Amount,
                description = Description,
                cancelUrl,
                returnUrl,
                expiredAt = new DateTimeOffset(order.ExpiresAtUtc, TimeSpan.Zero).ToUnixTimeSeconds(),
                signature = PaymentSignature.HmacSha256(_payOs.ChecksumKey, raw),
            });

            using var response = await _http.SendAsync(request);
            using var json = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync());
            var root = json.RootElement;
            if (Str(root, "code") != "00" || !root.TryGetProperty("data", out var data) || data.ValueKind != JsonValueKind.Object)
            {
                throw new PaymentGatewayException($"PayOS từ chối tạo đơn: {Str(root, "desc") ?? response.StatusCode.ToString()}");
            }

            var bin = Str(data, "bin") ?? string.Empty;
            return new GatewayCheckout
            {
                PaymentUrl = Str(data, "checkoutUrl"),
                QrData = Str(data, "qrCode"),
                BankTransfer = new BankTransferInfo
                {
                    BankName = BankNames.GetValueOrDefault(bin, $"Ngân hàng (BIN {bin})"),
                    AccountNo = Str(data, "accountNumber") ?? string.Empty,
                    AccountName = Str(data, "accountName") ?? string.Empty,
                    Content = Str(data, "description") ?? Description,
                },
            };
        }

        public async Task<GatewayResult?> QueryAsync(long orderCode)
        {
            if (!UsePayOs) return null; // QR tĩnh: không hỏi được ai

            using var request = NewRequest(HttpMethod.Get, $"/v2/payment-requests/{orderCode}");
            using var response = await _http.SendAsync(request);
            using var json = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync());
            var root = json.RootElement;
            if (Str(root, "code") != "00" || !root.TryGetProperty("data", out var data) || data.ValueKind != JsonValueKind.Object) return null;
            if (Long(data, "orderCode") != orderCode) return null;

            // PENDING / PROCESSING / UNDERPAID (chuyển thiếu, chờ chuyển nốt) -> chưa kết luận
            return Str(data, "status") switch
            {
                "PAID" => new GatewayResult(orderCode, true, Long(data, "amountPaid"), Str(data, "id"), null),
                "CANCELLED" => new GatewayResult(orderCode, false, 0, Str(data, "id"), "Đơn đã hủy trên PayOS"),
                "EXPIRED" => new GatewayResult(orderCode, false, 0, Str(data, "id"), "Hết hạn thanh toán"),
                "FAILED" => new GatewayResult(orderCode, false, 0, Str(data, "id"), "PayOS báo thanh toán thất bại"),
                _ => null,
            };
        }

        public async Task CancelAsync(long orderCode)
        {
            if (!UsePayOs) return;
            using var request = NewRequest(HttpMethod.Post, $"/v2/payment-requests/{orderCode}/cancel");
            request.Content = JsonContent.Create(new { cancellationReason = "Nguoi dung huy giao dich" });
            using var _ = await _http.SendAsync(request);
        }

        /// Webhook PayOS gửi về. Sai chữ ký / chưa cấu hình -> null.
        /// Chữ ký = HMAC-SHA256(ChecksumKey, "key1=value1&key2=value2..." của object data, key sắp theo bảng chữ cái).
        public GatewayResult? VerifyWebhook(JsonElement body)
        {
            if (!IsConfigured) return null; // chưa có key thì chữ ký rỗng ai cũng tự tạo được -> không tin
            if (!body.TryGetProperty("data", out var data) || data.ValueKind != JsonValueKind.Object) return null;

            var expected = PaymentSignature.HmacSha256(_payOs.ChecksumKey, ToSignatureString(data));
            if (!PaymentSignature.AreEqual(expected, Str(body, "signature"))) return null;

            var orderCode = Long(data, "orderCode");
            var success = Str(body, "code") == "00" && Str(data, "code") == "00";
            return new GatewayResult(orderCode, success, Long(data, "amount"), Str(data, "reference"), success ? null : Str(data, "desc"));
        }

        // Giống hàm convertObjToQueryStr trong SDK chính thức của PayOS (payos-lib-node)
        internal static string ToSignatureString(JsonElement data) =>
            string.Join("&", data.EnumerateObject()
                .OrderBy(p => p.Name, StringComparer.Ordinal)
                .Select(p => $"{p.Name}={SignatureValue(p.Value)}"));

        private static string SignatureValue(JsonElement value) => value.ValueKind switch
        {
            JsonValueKind.Null or JsonValueKind.Undefined => string.Empty,
            JsonValueKind.String => value.GetString() is "null" or "undefined" ? string.Empty : value.GetString()!,
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            JsonValueKind.Array => JsonSerializer.Serialize(value.EnumerateArray().Select(SortKeys).ToList(), JsStringify),
            JsonValueKind.Object => "[object Object]", // SDK chính thức không xử lý object lồng nhau
            _ => value.GetRawText(), // số
        };

        private static object? SortKeys(JsonElement e) => e.ValueKind == JsonValueKind.Object
            ? e.EnumerateObject().OrderBy(p => p.Name, StringComparer.Ordinal).ToDictionary(p => p.Name, p => (object)p.Value)
            : e;

        private HttpRequestMessage NewRequest(HttpMethod method, string path)
        {
            var request = new HttpRequestMessage(method, _payOs.BaseUrl.TrimEnd('/') + path);
            request.Headers.Add("x-client-id", _payOs.ClientId);
            request.Headers.Add("x-api-key", _payOs.ApiKey);
            return request;
        }

        private GatewayCheckout CreateStatic(GatewayOrder order)
        {
            var content = StaticTransferContent(order.OrderCode);
            return new GatewayCheckout
            {
                QrImageUrl = $"https://img.vietqr.io/image/{_static.BankCode}-{_static.AccountNo}-compact2.png"
                    + $"?amount={order.Amount}&addInfo={Uri.EscapeDataString(content)}&accountName={Uri.EscapeDataString(_static.AccountName)}",
                BankTransfer = new BankTransferInfo
                {
                    BankName = _static.BankName,
                    AccountNo = _static.AccountNo,
                    AccountName = _static.AccountName,
                    Content = content,
                },
            };
        }

        private static string? Str(JsonElement e, string name) =>
            e.TryGetProperty(name, out var v) ? (v.ValueKind == JsonValueKind.String ? v.GetString() : v.ValueKind == JsonValueKind.Null ? null : v.GetRawText()) : null;

        private static long Long(JsonElement e, string name) =>
            e.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.Number && v.TryGetInt64(out var n) ? n : 0;
    }
}
