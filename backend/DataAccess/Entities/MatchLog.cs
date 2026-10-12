namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Matches] - trận đã chơi cùng 1 đồng đội BLUSH. Người ghi (Reporter) khai, đồng đội (Teammate) xác nhận mới tính.
    public class MatchLog
    {
        public Guid Id { get; set; }
        public Guid ReporterId { get; set; }
        public Guid TeammateId { get; set; }
        public int GameId { get; set; }
        public string Result { get; set; } = MatchResult.Win;
        public string Status { get; set; } = MatchStatus.Pending;
        public DateTime CreatedAt { get; set; }
        public DateTime? ConfirmedAt { get; set; }

        public Game Game { get; set; } = null!;
    }

    public static class MatchResult
    {
        public const string Win = "Win";
        public const string Loss = "Loss";
    }

    public static class MatchStatus
    {
        public const string Pending = "Pending";
        public const string Confirmed = "Confirmed";
        public const string Rejected = "Rejected";
    }
}
