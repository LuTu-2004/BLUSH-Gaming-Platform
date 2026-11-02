using Blush.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Blush.Api.Hubs
{
    // ============================================================
    // SignalR: app kết nối /hubs/chat?access_token=<JWT> để NHẬN tin thời gian thực.
    // Gửi tin vẫn qua REST (api/chat/...) để kiểm tra quyền + lưu DB ở 1 chỗ, rồi ChatService phát lại:
    //   "message" (ChatMessageDto)  - tin mới trong 1 phòng của mình
    //   "room"    (ChatRoomDto)     - phòng thay đổi (VD: người kia vừa trả lời câu phá băng)
    // Mỗi người vào group "user:<id>" nên mở app trên nhiều máy đều nhận được.
    // Đang kết nối = đang online (PresenceTracker): gợi ý đồng đội hiện chấm xanh.
    // ============================================================
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly PresenceTracker _presence;

        public ChatHub(PresenceTracker presence)
        {
            _presence = presence;
        }

        public static string UserGroup(Guid userId) => $"user:{userId}";

        public override async Task OnConnectedAsync()
        {
            if (Guid.TryParse(Context.User?.FindFirst("sub")?.Value, out var userId))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));
                _presence.Connected(userId);
            }
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            if (Guid.TryParse(Context.User?.FindFirst("sub")?.Value, out var userId))
            {
                _presence.Disconnected(userId);
            }
            await base.OnDisconnectedAsync(exception);
        }
    }
}
