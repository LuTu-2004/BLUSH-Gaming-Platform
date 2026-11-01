namespace Blush.Api.Dtos
{
    // 1 người được gợi ý ghép đội
    public class MatchSuggestionDto
    {
        public Guid UserId { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string AvatarEmoji { get; set; } = "🎮";
        public string? AvatarUrl { get; set; }
        public int? Age { get; set; }
        public string? Mbti { get; set; }
        public string? Bio { get; set; }
        public string? Region { get; set; }
        public bool? UsesMic { get; set; }
        public bool IsVip { get; set; }
        public bool IsOnline { get; set; } // đang mở app (PresenceTracker)

        // Game chung hợp nhất để hiển thị
        public int GameId { get; set; }
        public string GameName { get; set; } = string.Empty;
        public string? Position { get; set; }
        public string? Purpose { get; set; }

        public List<string> Hobbies { get; set; } = new();

        /// Độ hợp 0-100
        public int Score { get; set; }

        /// Điểm chung, mỗi ý 1 cụm ngắn cách nhau " · " (VD "Valorant · Chơi vui, giải trí · Buổi tối"). App ghi nhãn "Điểm chung" phía trước.
        public string Reason { get; set; } = string.Empty;
    }
}
