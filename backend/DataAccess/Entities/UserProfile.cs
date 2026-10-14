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
        public string? TeammateWish { get; set; } // tự viết, AI đọc ra phong cách chơi

        // Phong cách chơi AI đọc từ Bio + TeammateWish (-2..2, null = chưa phân tích). Xem PlaystyleAnalyzer.
        public short? PlayCompetitive { get; set; } // -2 chill .. 2 tryhard
        public short? PlaySocial { get; set; }      // -2 im lặng .. 2 thích nói chuyện
        public short? PlayHumor { get; set; }       // -2 nghiêm túc .. 2 mê tấu hài
        public string? PlaystyleHash { get; set; }  // hash đoạn văn đã phân tích
        public DateTime? OnboardingCompletedAt { get; set; } // null = chưa làm khảo sát
        public DateTime UpdatedAt { get; set; }
    }
}
