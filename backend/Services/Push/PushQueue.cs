using System.Threading.Channels;

namespace Blush.Api.Services.Push
{
    public record PushMessage(Guid UserId, string Title, string? Body, string? Link, string? Tag);

    // Hàng đợi trong bộ nhớ giữa request (PushService.Enqueue) và FcmPushWorker gửi ở nền.
    // Đầy (Firebase chậm / mất mạng) thì bỏ tin cũ nhất: thông báo đẩy là phụ, đã có bản lưu trong app.
    public class PushQueue
    {
        private readonly Channel<PushMessage> _channel = Channel.CreateBounded<PushMessage>(
            new BoundedChannelOptions(1000) { FullMode = BoundedChannelFullMode.DropOldest, SingleReader = true });

        public void Add(PushMessage message) => _channel.Writer.TryWrite(message);

        public IAsyncEnumerable<PushMessage> ReadAllAsync(CancellationToken ct) => _channel.Reader.ReadAllAsync(ct);
    }
}
