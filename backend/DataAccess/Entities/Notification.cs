namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Notifications] - thông báo trong app. ReadAt null = chưa đọc.
    public class Notification
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Type { get; set; } = string.Empty; // NotificationType
        public string Title { get; set; } = string.Empty;
        public string? Body { get; set; }
        public string? Link { get; set; } // nơi mở khi bấm: 'zone:2', 'chat:<userId>', 'vip', 'quests'
        public DateTime CreatedAt { get; set; }
        public DateTime? ReadAt { get; set; }
    }

    public static class NotificationType
    {
        public const string PostLiked = "PostLiked";
        public const string PostCommented = "PostCommented";
        public const string ReportResolved = "ReportResolved"; // báo cáo mình gửi đã được xử lý
        public const string Warning = "Warning";               // Staff cảnh báo / tạm khóa mình
        public const string QuestCompleted = "QuestCompleted";
        public const string VipActivated = "VipActivated";
        public const string VipExpiring = "VipExpiring";
    }
}
