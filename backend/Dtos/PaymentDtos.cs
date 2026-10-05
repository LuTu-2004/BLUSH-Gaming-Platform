using System.ComponentModel.DataAnnotations;
using Blush.Api.Services.Payments;

namespace Blush.Api.Dtos
{
    public class CheckoutRequest
    {
        // Khớp cột VipPackages.PackageCode: 'month_basic', 'month_pro', 'quarter_pro'
        [Required(ErrorMessage = "Vui lòng chọn gói.")]
        public string PackageCode { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng chọn phương thức thanh toán.")]
        [RegularExpression("^(MoMo|VietQR)$", ErrorMessage = "Phương thức thanh toán không hợp lệ.")]
        public string Method { get; set; } = string.Empty;
    }

    public class MockCompleteRequest
    {
        /// true = giả lập trả tiền thành công, false = giả lập thất bại
        public bool Success { get; set; }
    }

    public class VipPackageDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int DurationDays { get; set; }
        public int AiTokenLimit { get; set; }
        public string? Description { get; set; }
        public string? Badge { get; set; }
    }

    public class PaymentMethodDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        /// false = chế độ Sandbox mà chưa cấu hình key -> app hiện "Chưa hỗ trợ"
        public bool IsAvailable { get; set; }
    }

    /// Kết quả bấm "Thanh toán": app dựa vào đây để mở trang thanh toán / hiện QR
    public class CheckoutDto
    {
        public long OrderCode { get; set; }
        public decimal Amount { get; set; }
        public string PackageCode { get; set; } = string.Empty;
        public string PackageName { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime? ExpiresAt { get; set; }

        /// true = chế độ Mock: app tự hiện trang giả lập, không mở PaymentUrl
        public bool IsMock { get; set; }

        /// Link trang thanh toán MoMo / PayOS (chế độ Sandbox/Production)
        public string? PaymentUrl { get; set; }

        /// VietQR: chuỗi QR (PayOS) để app tự vẽ, hoặc ảnh QR tĩnh (Mock) + thông tin chuyển khoản
        public string? QrData { get; set; }
        public string? QrImageUrl { get; set; }
        public BankTransferInfo? BankTransfer { get; set; }
    }

    public class TransactionDto
    {
        public long OrderCode { get; set; }
        public decimal Amount { get; set; }
        public string PackageCode { get; set; } = string.Empty;
        public string PackageName { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty; // Pending | Paid | Failed | Cancelled
        public string? FailureReason { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? PaidAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
    }
}
