namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Transactions] - mỗi lần bấm thanh toán là 1 dòng. Không bao giờ xóa (chứng từ tài chính).
    public class Transaction
    {
        public Guid Id { get; set; }
        public long OrderCode { get; set; }        // Mã đơn gửi sang cổng thanh toán
        public Guid UserId { get; set; }
        public int VipPackageId { get; set; }
        public decimal Amount { get; set; }
        public string PaymentMethod { get; set; } = PaymentMethods.VietQr;
        public string Status { get; set; } = TransactionStatus.Pending;
        public string? GatewayTransactionId { get; set; }
        public string? FailureReason { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? PaidAt { get; set; }

        public VipPackage VipPackage { get; set; } = null!;
    }

    // Giá trị hợp lệ của cột Transactions.Status (khớp CHECK trong SQL)
    public static class TransactionStatus
    {
        public const string Pending = "Pending";
        public const string Paid = "Paid";
        public const string Failed = "Failed";
        public const string Cancelled = "Cancelled";
    }

    // Giá trị hợp lệ của cột Transactions.PaymentMethod (khớp CHECK trong SQL)
    public static class PaymentMethods
    {
        public const string MoMo = "MoMo";
        // Không còn nhận thanh toán mới, chỉ giữ để hiển thị giao dịch cũ
        public const string VnPay = "VNPay";
        public const string ZaloPay = "ZaloPay";
        public const string VietQr = "VietQR";
        public const string VietQrPayOs = "VietQR_PayOS"; // giá trị cũ trước migration 005

        public static string LabelOf(string method) => method switch
        {
            MoMo => "Ví MoMo",
            VnPay => "VNPay",
            ZaloPay => "Ví ZaloPay",
            VietQr or VietQrPayOs => "Chuyển khoản VietQR",
            _ => method,
        };
    }
}
