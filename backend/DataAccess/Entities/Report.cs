namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Reports] - người chơi báo cáo vi phạm, Staff xử lý
    public class Report
    {
        public int Id { get; set; }
        public Guid ReporterId { get; set; }
        public Guid ReportedUserId { get; set; }
        public string Reason { get; set; } = string.Empty;
        public string Severity { get; set; } = ReportSeverity.Medium;
        public string Status { get; set; } = ReportStatus.Pending;
        public string? ActionTaken { get; set; } // ReportAction, null = chưa xử lý
        public Guid? ResolvedBy { get; set; }
        public DateTime? ResolvedAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // Giá trị hợp lệ (khớp CHECK trong SQL)
    public static class ReportSeverity
    {
        public const string High = "High";
        public const string Medium = "Medium";
        public const string Low = "Low";
    }

    public static class ReportStatus
    {
        public const string Pending = "Pending";
        public const string Resolved = "Resolved";
    }

    public static class ReportAction
    {
        public const string Warn = "Warn";
        public const string Suspend = "Suspend"; // tạm khóa người bị báo cáo SuspendDays ngày
        public const string Dismiss = "Dismiss";

        public const int SuspendDays = 3;
    }

    // Lý do người chơi chọn khi báo cáo -> mức độ nghiêm trọng (người báo cáo không tự chọn mức độ)
    public static class ReportReason
    {
        public record Item(string Code, string Label, string Severity);

        public static readonly IReadOnlyList<Item> All = new[]
        {
            new Item("Toxic", "Chửi thề, xúc phạm", ReportSeverity.High),
            new Item("Harassment", "Quấy rối, đe dọa", ReportSeverity.High),
            new Item("Scam", "Lừa đảo", ReportSeverity.High),
            new Item("Griefing", "Phá trận, treo máy, gian lận", ReportSeverity.Medium),
            new Item("Spam", "Spam, quảng cáo", ReportSeverity.Low),
            new Item("Other", "Lý do khác", ReportSeverity.Medium),
        };

        public static Item? Find(string code) => All.FirstOrDefault(r => r.Code == code);
    }
}
