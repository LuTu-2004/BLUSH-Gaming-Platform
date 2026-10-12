using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // Thông báo trong app: lưu DB + đẩy ngay qua SignalR (sự kiện "notification" ở /hubs/chat).
    public interface INotificationService
    {
        /// Gọi SAU khi đã lưu / commit thay đổi chính (thông báo lỗi không làm hỏng thao tác chính)
        Task NotifyAsync(Guid userId, string type, string title, string? body = null, string? link = null);

        Task<List<NotificationDto>> GetAsync(Guid userId, DateTime? before);
        Task<NotificationSummaryDto> GetSummaryAsync(Guid userId);

        /// [id] null = đánh dấu tất cả đã đọc
        Task MarkReadAsync(Guid userId, Guid? id);
    }

    // Gửi thông báo đẩy ra ngoài app (VD Firebase Cloud Messaging). Chưa đăng ký class nào thì chỉ có thông báo trong app.
    public interface INotificationPusher
    {
        Task PushAsync(Guid userId, NotificationDto notification);
    }
}
