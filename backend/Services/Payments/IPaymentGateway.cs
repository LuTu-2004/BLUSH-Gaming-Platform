using System.Security.Cryptography;
using System.Text;

namespace Blush.Api.Services.Payments
{
    // ============================================================
    // Cổng thanh toán (MoMo, VNPay, ZaloPay, VietQR). Mỗi cổng 1 class cài interface này.
    // Thêm cổng mới: viết class mới + đăng ký trong Program.cs, PaymentService không phải sửa.
    // ============================================================
    public interface IPaymentGateway
    {
        /// Khớp cột Transactions.PaymentMethod (PaymentMethods.*)
        string Method { get; }

        /// Đã có đủ key để gọi cổng thật chưa (chế độ Sandbox)
        bool IsConfigured { get; }

        /// Tạo đơn bên cổng thanh toán, trả về link/QR để người dùng trả tiền
        Task<GatewayCheckout> CreateAsync(GatewayOrder order);
    }

    /// Thông tin đơn gửi sang cổng
    public record GatewayOrder(long OrderCode, long Amount, string PackageCode, string ClientIp, DateTime ExpiresAtUtc);

    /// Kết quả tạo đơn: link trang thanh toán (MoMo/VNPay/ZaloPay) hoặc QR chuyển khoản (VietQR)
    public class GatewayCheckout
    {
        public string? PaymentUrl { get; set; }
        public string? QrImageUrl { get; set; }
        public BankTransferInfo? BankTransfer { get; set; }
    }

    public class BankTransferInfo
    {
        public string BankName { get; set; } = string.Empty;
        public string AccountNo { get; set; } = string.Empty;
        public string AccountName { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty; // nội dung chuyển khoản phải ghi đúng để đối soát
    }

    /// Kết quả cổng báo về (IPN / callback / redirect) sau khi đã kiểm tra chữ ký
    public record GatewayResult(long OrderCode, bool Success, long Amount, string? GatewayTransactionId, string? Message);

    /// Lỗi khi gọi cổng thanh toán (sai key, cổng từ chối...)
    public class PaymentGatewayException : Exception
    {
        public PaymentGatewayException(string message) : base(message) { }
    }

    // Ký dữ liệu: các cổng đều dùng HMAC (VNPay: SHA512, MoMo & ZaloPay: SHA256), kết quả dạng hex chữ thường
    public static class PaymentSignature
    {
        public static string HmacSha256(string key, string data) =>
            Convert.ToHexString(HMACSHA256.HashData(Encoding.UTF8.GetBytes(key), Encoding.UTF8.GetBytes(data))).ToLowerInvariant();

        public static string HmacSha512(string key, string data) =>
            Convert.ToHexString(HMACSHA512.HashData(Encoding.UTF8.GetBytes(key), Encoding.UTF8.GetBytes(data))).ToLowerInvariant();

        /// So sánh chữ ký không để lộ thời gian (chống đoán dần từng ký tự)
        public static bool AreEqual(string expected, string? actual) =>
            actual != null && CryptographicOperations.FixedTimeEquals(
                Encoding.ASCII.GetBytes(expected.ToLowerInvariant()),
                Encoding.ASCII.GetBytes(actual.ToLowerInvariant()));
    }
}
