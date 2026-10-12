using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Hubs;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Thông báo trong app
    //   Lưu bảng Notifications, đẩy ngay qua SignalR, rồi gọi các INotificationPusher (Firebase... nếu có).
    //   VIP sắp hết hạn: tạo lúc người dùng mở app (GetSummaryAsync), không cần tác vụ chạy nền.
    // ============================================================
    public class NotificationService : INotificationService
    {
        public const int PageSize = 30;
        private static readonly TimeSpan VipWarningBefore = TimeSpan.FromDays(3);

        private readonly BlushDbContext _context;
        private readonly IHubContext<ChatHub> _hub;
        private readonly IEnumerable<INotificationPusher> _pushers;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(BlushDbContext context, IHubContext<ChatHub> hub, IEnumerable<INotificationPusher> pushers, ILogger<NotificationService> logger)
        {
            _context = context;
            _hub = hub;
            _pushers = pushers;
            _logger = logger;
        }

        public async Task NotifyAsync(Guid userId, string type, string title, string? body = null, string? link = null)
        {
            try
            {
                var notification = new Notification
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Type = type,
                    Title = Cut(title, 120),
                    Body = body == null ? null : Cut(body, 300),
                    Link = link,
                    CreatedAt = DateTime.UtcNow,
                };
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();

                var dto = ToDto(notification);
                await _hub.Clients.Group(ChatHub.UserGroup(userId)).SendAsync("notification", dto);
                foreach (var pusher in _pushers) await pusher.PushAsync(userId, dto);
            }
            catch (Exception ex)
            {
                // Thông báo là phụ: lỗi ở đây không được làm hỏng thao tác chính (thả tim, thanh toán...).
                // Bỏ bản ghi lỗi khỏi bộ nhớ EF để lần SaveChanges sau trong cùng request không lưu lại nó.
                foreach (var entry in _context.ChangeTracker.Entries<Notification>().Where(e => e.State == EntityState.Added).ToList())
                {
                    entry.State = EntityState.Detached;
                }
                _logger.LogWarning(ex, "Gửi thông báo {Type} cho {UserId} thất bại", type, userId);
            }
        }

        public async Task<List<NotificationDto>> GetAsync(Guid userId, DateTime? before)
        {
            var query = _context.Notifications.AsNoTracking().Where(n => n.UserId == userId);
            if (before != null) query = query.Where(n => n.CreatedAt < before);
            var list = await query.OrderByDescending(n => n.CreatedAt).Take(PageSize).ToListAsync();
            return list.Select(ToDto).ToList();
        }

        public async Task<NotificationSummaryDto> GetSummaryAsync(Guid userId)
        {
            await CreateVipExpiringNoticeAsync(userId);

            var unreadChats = await _context.ChatRooms
                .Where(r => (r.User1Id == userId || r.User2Id == userId)
                    && !_context.UserBlocks.Any(b => (b.BlockerId == r.User1Id && b.BlockedId == r.User2Id) || (b.BlockerId == r.User2Id && b.BlockedId == r.User1Id)))
                .CountAsync(r => _context.ChatMessages.Any(m => m.RoomId == r.Id && m.SenderId != null && m.SenderId != userId
                    && (r.User1Id == userId
                        ? r.User1LastReadAt == null || m.CreatedAt > r.User1LastReadAt
                        : r.User2LastReadAt == null || m.CreatedAt > r.User2LastReadAt)));

            return new NotificationSummaryDto
            {
                UnreadNotifications = await _context.Notifications.CountAsync(n => n.UserId == userId && n.ReadAt == null),
                UnreadChats = unreadChats,
            };
        }

        public async Task MarkReadAsync(Guid userId, Guid? id)
        {
            await _context.Notifications
                .Where(n => n.UserId == userId && n.ReadAt == null && (id == null || n.Id == id))
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.ReadAt, DateTime.UtcNow));
        }

        // Gói VIP hết hạn trong 3 ngày tới mà chưa có thông báo cho lần hết hạn này -> tạo 1 thông báo
        private async Task CreateVipExpiringNoticeAsync(Guid userId)
        {
            var now = DateTime.UtcNow;
            var endAt = await _context.UserSubscriptions
                .Where(s => s.UserId == userId && s.EndAt > now)
                .MaxAsync(s => (DateTime?)s.EndAt);
            if (endAt == null || endAt - now > VipWarningBefore) return;

            var windowStart = endAt.Value - VipWarningBefore;
            var alreadySent = await _context.Notifications.AnyAsync(n => n.UserId == userId && n.Type == NotificationType.VipExpiring && n.CreatedAt >= windowStart);
            if (alreadySent) return;

            var days = Math.Max(1, (int)Math.Ceiling((endAt.Value - now).TotalDays));
            await NotifyAsync(userId, NotificationType.VipExpiring, $"BLUSH Pass sắp hết hạn trong {days} ngày",
                "Gia hạn để giữ huy hiệu VIP và lượt AI mỗi ngày.", "vip");
        }

        private static NotificationDto ToDto(Notification n) => new()
        {
            Id = n.Id,
            Type = n.Type,
            Title = n.Title,
            Body = n.Body,
            Link = n.Link,
            CreatedAt = n.CreatedAt,
            IsRead = n.ReadAt != null,
        };

        private static string Cut(string text, int max) => text.Length <= max ? text : text[..(max - 1)].TrimEnd() + "…";
    }
}
