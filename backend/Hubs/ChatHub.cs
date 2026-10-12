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
    // ============================================================
    [Authorize]
    public class ChatHub : Hub
    {
        public static string UserGroup(Guid userId) => $"user:{userId}";

        public override async Task OnConnectedAsync()
        {
            if (Guid.TryParse(Context.User?.FindFirst("sub")?.Value, out var userId))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));
            }
            await base.OnConnectedAsync();
        }
    }
}
