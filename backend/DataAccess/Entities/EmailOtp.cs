namespace Blush.Api.DataAccess.Entities
{
    // Bảng [EmailOtps] - mã 6 số gửi qua email (chỉ lưu bản băm)
    public class EmailOtp
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Purpose { get; set; } = string.Empty;
        public string CodeHash { get; set; } = string.Empty;
        public int Attempts { get; set; }
        public DateTime ExpiresAt { get; set; }
        public DateTime? ConsumedAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // Giá trị hợp lệ của cột EmailOtps.Purpose (khớp CHECK trong SQL)
    public static class OtpPurpose
    {
        public const string VerifyEmail = "VerifyEmail";
        public const string ResetPassword = "ResetPassword";
        public const string TwoFactorLogin = "TwoFactorLogin";
        public const string EnableTwoFactor = "EnableTwoFactor"; // xác nhận nhận được mã trước khi bật 2 bước

        // Các loại mã được phép xin gửi lại qua api/auth/resend-otp (không cần đăng nhập).
        // EnableTwoFactor KHÔNG nằm đây: muốn gửi lại phải nhập lại mật khẩu.
        public static bool IsValid(string purpose) => purpose is VerifyEmail or ResetPassword or TwoFactorLogin;
    }
}
