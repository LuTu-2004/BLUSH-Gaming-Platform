using System.Collections.Concurrent;

namespace Blush.Api.Services
{
    // Ai đang online = đang mở app (giữ kết nối SignalR /hubs/chat, xem ChatHub).
    // Đếm số kết nối mỗi người vì 1 người có thể mở app trên nhiều máy. Lưu trong RAM:
    // khởi động lại backend thì mọi người offline đến khi app tự kết nối lại; chạy nhiều server cần chuyển sang Redis.
    public class PresenceTracker
    {
        private readonly ConcurrentDictionary<Guid, int> _connections = new();

        public void Connected(Guid userId) => _connections.AddOrUpdate(userId, 1, (_, n) => n + 1);

        public void Disconnected(Guid userId)
        {
            while (_connections.TryGetValue(userId, out var n))
            {
                var removed = n <= 1
                    ? _connections.TryRemove(new KeyValuePair<Guid, int>(userId, n))
                    : _connections.TryUpdate(userId, n - 1, n);
                if (removed) return;
            }
        }

        public bool IsOnline(Guid userId) => _connections.ContainsKey(userId);
    }
}
