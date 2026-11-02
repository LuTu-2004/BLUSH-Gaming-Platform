using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Push
{
    // Chạy nền suốt vòng đời backend: lấy tin trong PushQueue, gửi tới mọi điện thoại của người nhận.
    // Mã FCM không còn dùng được (gỡ app, xóa dữ liệu app) thì xóa luôn khỏi DB.
    public class FcmPushWorker : BackgroundService
    {
        private readonly PushQueue _queue;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<FcmPushWorker> _logger;

        public FcmPushWorker(PushQueue queue, IServiceScopeFactory scopeFactory, ILogger<FcmPushWorker> logger)
        {
            _queue = queue;
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await foreach (var message in _queue.ReadAllAsync(stoppingToken))
            {
                try
                {
                    await SendAsync(message, stoppingToken);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Gửi thông báo đẩy cho {UserId} thất bại", message.UserId);
                }
            }
        }

        private async Task SendAsync(PushMessage message, CancellationToken ct)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<BlushDbContext>();
            var fcm = scope.ServiceProvider.GetRequiredService<FcmClient>();

            // Tài khoản bị khóa / tạm khóa thì không gửi (máy họ có thể vẫn còn mã từ lúc đăng nhập)
            var tokens = await context.DeviceTokens
                .Where(d => d.UserId == message.UserId && context.Users.Any(u => u.Id == d.UserId && u.Status == UserStatus.Active))
                .Select(d => d.Token)
                .ToListAsync(ct);

            var invalid = new List<string>();
            foreach (var token in tokens)
            {
                if (await fcm.SendAsync(token, message, ct) == FcmResult.InvalidToken) invalid.Add(token);
            }
            if (invalid.Count > 0)
            {
                await context.DeviceTokens.Where(d => invalid.Contains(d.Token)).ExecuteDeleteAsync(ct);
            }
        }
    }
}
