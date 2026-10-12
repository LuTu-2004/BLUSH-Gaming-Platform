namespace Blush.Api.Dtos
{
    public class QuestResultDto
    {
        public string Message { get; set; } = string.Empty;
        public int AddedCoins { get; set; }
        public int AddedExp { get; set; }
        public UserDto User { get; set; } = null!;
    }

    // 1 nhiệm vụ + tiến độ của người đang đăng nhập trong kỳ hiện tại
    public class QuestDto
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Type { get; set; } = string.Empty; // Daily / Weekly / Seasonal
        public int Target { get; set; }
        public int Current { get; set; }
        public int RewardCoins { get; set; }
        public int RewardExp { get; set; }
        public bool IsCompleted { get; set; }
        public bool IsClaimed { get; set; }
        public DateOnly PeriodStart { get; set; }
    }
}
