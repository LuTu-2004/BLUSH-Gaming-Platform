namespace Blush.Api.Dtos
{
    // Dữ liệu người dùng trả về cho Frontend.
    // KHÔNG trả thẳng entity User vì nó chứa PasswordHash.
    public class UserDto
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public DateOnly? DateOfBirth { get; set; }
        public string? Mbti { get; set; }
        public string? Bio { get; set; }
        public string? Region { get; set; }
        public string AvatarEmoji { get; set; } = "🎮";
        public string? AvatarUrl { get; set; }
        public string? SundayAnswer { get; set; }
        public string? OverthinkAnswer { get; set; }
        public int CurrentLevel { get; set; }
        public int Exp { get; set; }
        public int Coins { get; set; }
        public bool IsVip { get; set; }
        public DateTime? VipExpireAt { get; set; }
        public string? VipPackageName { get; set; } // gói đang dùng (gói hết hạn muộn nhất)
        public DateOnly? LastCheckInDate { get; set; }

        // Bảo mật: app dùng để hiện công tắc "Xác thực 2 bước" (chỉ tài khoản có mật khẩu mới bật được)
        public bool HasPassword { get; set; }
        public bool TwoFactorEnabled { get; set; }

        // false = chưa làm khảo sát sau đăng ký -> app chuyển sang màn Onboarding (chỉ áp dụng role User)
        public bool OnboardingCompleted { get; set; }
    }
}
