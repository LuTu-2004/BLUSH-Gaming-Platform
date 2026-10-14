using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // App gửi mã FCM sau khi đăng nhập / khi Firebase cấp mã mới
    public class RegisterDeviceRequest
    {
        [Required, MaxLength(512)]
        public string Token { get; set; } = string.Empty;

        [Required, RegularExpression("^(android|ios|web)$", ErrorMessage = "Platform phải là android, ios hoặc web.")]
        public string Platform { get; set; } = string.Empty;
    }

    // Đăng xuất: gỡ mã của máy này để không nhận thông báo của tài khoản vừa thoát
    public class UnregisterDeviceRequest
    {
        [Required, MaxLength(512)]
        public string Token { get; set; } = string.Empty;
    }
}
