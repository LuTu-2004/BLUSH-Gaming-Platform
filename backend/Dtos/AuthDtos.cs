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
    }

    public class LoginRequest
    {
        [Required(ErrorMessage = "Vui lòng nhập email.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mật khẩu.")]
        public string Password { get; set; } = string.Empty;
    }

    public class GoogleLoginRequest
    {
        // ID Token lấy được từ Google Sign-In trên app Flutter
        [Required(ErrorMessage = "Thiếu Google ID Token.")]
        public string IdToken { get; set; } = string.Empty;
    }

    public class AuthResponse
    {
        public string AccessToken { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public bool IsNewUser { get; set; } // true = lần đầu vào app -> Flutter chuyển sang màn Khảo sát
        public UserDto User { get; set; } = null!;
    }
}
