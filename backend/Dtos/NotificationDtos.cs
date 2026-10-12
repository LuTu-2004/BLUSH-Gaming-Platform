namespace Blush.Api.Dtos
{
    public class NotificationDto
    {
        public Guid Id { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Body { get; set; }
        public string? Link { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsRead { get; set; }
    }

    // Số trên nút 🔔 và 💬
    public class NotificationSummaryDto
    {
        public int UnreadNotifications { get; set; }
        public int UnreadChats { get; set; } // số cuộc trò chuyện có tin chưa đọc
    }
}
