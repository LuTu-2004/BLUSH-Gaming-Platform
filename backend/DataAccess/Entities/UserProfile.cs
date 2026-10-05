namespace Blush.Api.DataAccess.Entities
{
    // Bảng [UserProfiles] - hồ sơ hiển thị, quan hệ 1-1 với User
    public class UserProfile
    {
        public Guid UserId { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public DateOnly? DateOfBirth { get; set; }
        public string? Mbti { get; set; }
        public string? Bio { get; set; }
        public string? Lifestyle { get; set; }
        public string? Region { get; set; }
        public string AvatarEmoji { get; set; } = "🎮";
        public string? AvatarUrl { get; set; }
        public string AvatarFrame { get; set; } = "Normal";
        public string? SundayAnswer { get; set; }
        public string? OverthinkAnswer { get; set; }

        // Onboarding sau đăng ký (dữ liệu ghép đội)
        public bool? UsesMic { get; set; } // null = tùy trận
        public string? TeammateWish { get; set; } // tự viết, để dành cho AI đọc
        public DateTime? OnboardingCompletedAt { get; set; } // null = chưa làm khảo sát
        public DateTime UpdatedAt { get; set; }
    }
}
