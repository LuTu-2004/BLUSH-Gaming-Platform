namespace Blush.Api.Dtos
{
    // GET api/leaderboard: top game thủ theo EXP + hạng của người đang xem
    public class LeaderboardDto
    {
        public List<LeaderboardEntryDto> Items { get; set; } = new();

        // null = người xem không có trong bảng đang lọc (Staff/Admin, chưa làm khảo sát, khác khu vực / game)
        public LeaderboardEntryDto? Me { get; set; }
    }

    public class LeaderboardEntryDto
    {
        public int Rank { get; set; } // bằng EXP thì cùng hạng (1, 2, 2, 4...)
        public Guid UserId { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string AvatarEmoji { get; set; } = "🎮";
        public string? AvatarUrl { get; set; }
        public string? Mbti { get; set; }
        public string? Region { get; set; }
        public int Level { get; set; }
        public int Exp { get; set; }
        public string? GameName { get; set; } // game đang lọc, hoặc 1 game người đó chơi
        public bool IsMe { get; set; }
    }
}
