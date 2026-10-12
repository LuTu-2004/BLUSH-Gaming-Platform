namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Quests] - danh sách nhiệm vụ (Admin thêm/sửa trong DB)
    public class Quest
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty; // QuestCode: code backend dùng để cộng tiến độ
        public string TitleVI { get; set; } = string.Empty;
        public string? TitleEN { get; set; }
        public string? DescVI { get; set; }
        public string QuestType { get; set; } = string.Empty; // QuestType
        public int TargetCount { get; set; }
        public int RewardExp { get; set; }
        public int RewardCoins { get; set; }
        public bool IsActive { get; set; }
    }

    // Bảng [UserQuests] - tiến độ của 1 người cho 1 nhiệm vụ trong 1 kỳ (ngày / tuần / mùa)
    public class UserQuest
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public int QuestId { get; set; }
        public DateOnly PeriodStart { get; set; }
        public int CurrentProgress { get; set; }
        public DateTime? CompletedAt { get; set; } // null = chưa xong
        public DateTime? ClaimedAt { get; set; }   // null = chưa bấm "Nhận quà"

        public Quest Quest { get; set; } = null!;
    }

    // Giá trị hợp lệ của cột QuestType (khớp CHECK trong SQL)
    public static class QuestType
    {
        public const string Daily = "Daily";
        public const string Weekly = "Weekly";
        public const string Seasonal = "Seasonal";

        // Ngày bắt đầu kỳ chứa [today]: sang kỳ mới thì tạo dòng UserQuests mới -> nhiệm vụ tự "reset".
        // Chưa có bảng mùa giải nên tạm coi 1 mùa = 1 quý (3 tháng).
        public static DateOnly PeriodStartOf(string type, DateOnly today) => type switch
        {
            Weekly => today.AddDays(-(((int)today.DayOfWeek + 6) % 7)), // thứ Hai
            Seasonal => new DateOnly(today.Year, (today.Month - 1) / 3 * 3 + 1, 1),
            _ => today,
        };
    }

    // Code của các nhiệm vụ có sẵn (khớp cột Quests.Code). Tính năng nào làm xong thì gọi
    // IQuestService.RecordProgressAsync(userId, QuestCode.Xxx) ở đó để cộng tiến độ.
    public static class QuestCode
    {
        public const string DailyMatch = "daily_match";           // đã nối: xem gợi ý đồng đội
        public const string DailyFeedPost = "daily_feed_post";     // chờ tính năng Feed
        public const string DailyFeedLike = "daily_feed_like";     // chờ tính năng Feed
        public const string DailyPlayTeam = "daily_play_team";     // chờ tính năng trận đấu
        public const string WeeklyWinStreak = "weekly_win_streak"; // chờ tính năng trận đấu
        public const string WeeklyHelpNewbie = "weekly_help_newbie";
        public const string SeasonMasterRank = "season_master_rank";
        public const string SeasonFeedInteract = "season_feed_interact";
    }
}
