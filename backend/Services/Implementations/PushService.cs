using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Options;
using Blush.Api.Services.Interfaces;
using Blush.Api.Services.Push;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Thông báo đẩy (Firebase Cloud Messaging)
    //   Lưu mã FCM của từng điện thoại; Enqueue chỉ xếp hàng, FcmPushWorker gửi ở nền.
    //   Cũng là INotificationPusher: mọi thông báo trong app (thả tim, bình luận, VIP...) tự có bản đẩy.
    // ============================================================
    public class PushService : IPushService, INotificationPusher
    {
        public const int MaxDevicesPerUser = 10;

        private readonly BlushDbContext _context;
        private readonly PushQueue _queue;
        private readonly FirebaseOptions _options;

        public PushService(BlushDbContext context, PushQueue queue, IOptions<FirebaseOptions> options)
        {
            _context = context;
            _queue = queue;
            _options = options.Value;
        }

        public async Task RegisterAsync(Guid userId, string token, string platform)
        {
            var now = DateTime.UtcNow;
            var device = await _context.DeviceTokens.FirstOrDefaultAsync(d => d.Token == token);
            if (device == null)
            {
                _context.DeviceTokens.Add(new DeviceToken { Id = Guid.NewGuid(), UserId = userId, Token = token, Platform = platform, CreatedAt = now, UpdatedAt = now });
            }
            else
            {
                device.UserId = userId;
                device.Platform = platform;
                device.UpdatedAt = now;
            }
            await _context.SaveChangesAsync();

            // Giữ tối đa 10 máy mới dùng gần nhất (máy cũ không gỡ mã khi bị reset)
            var stale = await _context.DeviceTokens
                .Where(d => d.UserId == userId)
                .OrderByDescending(d => d.UpdatedAt)
                .Skip(MaxDevicesPerUser)
                .Select(d => d.Id)
                .ToListAsync();
            if (stale.Count > 0) await _context.DeviceTokens.Where(d => stale.Contains(d.Id)).ExecuteDeleteAsync();
        }

        public async Task UnregisterAsync(Guid userId, string token)
        {
            await _context.DeviceTokens.Where(d => d.UserId == userId && d.Token == token).ExecuteDeleteAsync();
        }

        public void Enqueue(Guid userId, string title, string? body, string? link, string? tag = null)
        {
            if (!_options.IsConfigured) return;
            _queue.Add(new PushMessage(userId, title, body, link, tag));
        }

        public Task PushAsync(Guid userId, NotificationDto notification)
        {
            Enqueue(userId, notification.Title, notification.Body, notification.Link);
            return Task.CompletedTask;
        }
    }
}
