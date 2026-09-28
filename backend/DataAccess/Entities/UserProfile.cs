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
        public DateTime UpdatedAt { get; set; }
    }
}
