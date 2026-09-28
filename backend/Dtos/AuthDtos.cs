using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // Các [Required], [EmailAddress]... được [ApiController] tự kiểm tra,
    // sai thì tự trả về 400 Bad Request mà không cần viết if-else.

    public class RegisterRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        [MaxLength(255, ErrorMessage = "Email quá dài.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mật khẩu.")]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
        [MaxLength(100, ErrorMessage = "Mật khẩu quá dài.")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập tên hiển thị.")]
        [MaxLength(50, ErrorMessage = "Tên hiển thị tối đa 50 ký tự.")]
        public string DisplayName { get; set; } = string.Empty;

        // Dạng "2006-01-10". Bắt buộc, phải từ AgePolicy.MinimumAge tuổi trở lên.
        [Required(ErrorMessage = "Vui lòng nhập ngày sinh.")]
        public DateOnly? DateOfBirth { get; set; }
    }

    public class LoginRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mật khẩu.")]
        public string Password { get; set; } = string.Empty;

        // Token "thiết bị tin cậy" app đã lưu từ lần xác thực 2 bước trước (nếu có) -> bỏ qua bước nhập mã
        public string? DeviceToken { get; set; }
    }

    // Bước 2 của đăng nhập: nhập mã gửi về email
    public class TwoFactorLoginRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mã xác minh.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Mã xác minh gồm 6 chữ số.")]
        public string Code { get; set; } = string.Empty;

        // true = "Tin cậy thiết bị này 30 ngày"
        public bool RememberDevice { get; set; }

        [MaxLength(100)]
        public string? DeviceName { get; set; }
    }

    // Xác nhận lại mật khẩu trước thao tác bảo mật (bật/tắt 2 bước)
    public class PasswordConfirmRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập mật khẩu hiện tại.")]
        public string Password { get; set; } = string.Empty;
    }

    // Nhập mã 6 số (VD: xác nhận bật 2 bước)
    public class CodeRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập mã xác minh.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Mã xác minh gồm 6 chữ số.")]
        public string Code { get; set; } = string.Empty;
    }

    public class GoogleLoginRequest
    {
        // ID Token lấy được từ Google Sign-In trên app Flutter
        [Required(ErrorMessage = "Thiếu Google ID Token.")]
        public string IdToken { get; set; } = string.Empty;
    }

    public class VerifyEmailRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mã xác minh.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Mã xác minh gồm 6 chữ số.")]
        public string Code { get; set; } = string.Empty;
    }

    public class ResendOtpRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;

        // "VerifyEmail" hoặc "ResetPassword"
        [Required]
        public string Purpose { get; set; } = string.Empty;
    }

    public class ForgotPasswordRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;
    }

    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mã xác minh.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Mã xác minh gồm 6 chữ số.")]
        public string Code { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mật khẩu mới.")]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
        [MaxLength(100, ErrorMessage = "Mật khẩu quá dài.")]
        public string NewPassword { get; set; } = string.Empty;
    }

    public class AuthResponse
    {
        public string AccessToken { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public bool IsNewUser { get; set; } // true = lần đầu vào app -> Flutter chuyển sang màn Khảo sát
        public UserDto User { get; set; } = null!;

        // Chỉ có khi vừa chọn "Tin cậy thiết bị này 30 ngày". App lưu lại, lần sau gửi kèm khi đăng nhập.
        public string? DeviceToken { get; set; }
    }

    // Trả về cho các API chỉ cần 1 câu thông báo (đăng ký, gửi mã, đặt lại mật khẩu)
    public class MessageResponse
    {
        public string Message { get; set; } = string.Empty;
        public string? Email { get; set; }
    }
}
