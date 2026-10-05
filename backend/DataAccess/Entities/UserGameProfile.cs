namespace Blush.Api.DataAccess.Entities
{
    // Bảng [UserGameProfiles] - người dùng chơi game nào, vị trí nào, chơi để làm gì
    public class UserGameProfile
    {
        public Guid UserId { get; set; }
        public int GameId { get; set; }
        public string? PreferredPosition { get; set; }
        public string? Purpose { get; set; } // GamePurpose
        public DateTime UpdatedAt { get; set; }

        public Game Game { get; set; } = null!;
    }
}
