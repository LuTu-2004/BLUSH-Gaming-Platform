using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Chat 1-1 (cần token). Nhận tin mới qua SignalR: /hubs/chat
    //   GET  api/chat/rooms                           - Danh sách phòng của mình (mới nhắn lên trước)
    //   POST api/chat/rooms                           - Mở phòng với 1 người { userId } (có rồi thì trả phòng cũ)
    //   GET  api/chat/rooms/{id}                      - 1 phòng
    //   GET  api/chat/rooms/{id}/messages?before=&limit=50 - Tin nhắn (cũ -> mới), before = tải tin cũ hơn
    //   POST api/chat/rooms/{id}/messages             - Gửi tin { content }
    //   POST api/chat/rooms/{id}/icebreaker           - Trả lời câu phá băng { choice: "A" | "B" }
    // ============================================================
    [Authorize]
    public class ChatController : ApiControllerBase
    {
        private readonly IChatService _chatService;

        public ChatController(IChatService chatService)
        {
            _chatService = chatService;
        }

        [HttpGet("rooms")]
        public async Task<IActionResult> GetRooms() => Ok(await _chatService.GetRoomsAsync(User.GetUserId()));

        [HttpPost("rooms")]
        public async Task<IActionResult> OpenRoom([FromBody] OpenChatRequest request) =>
            ToActionResult(await _chatService.OpenRoomAsync(User.GetUserId(), request.UserId!.Value));

        [HttpGet("rooms/{id:guid}")]
        public async Task<IActionResult> GetRoom(Guid id) => ToActionResult(await _chatService.GetRoomAsync(User.GetUserId(), id));

        [HttpGet("rooms/{id:guid}/messages")]
        public async Task<IActionResult> GetMessages(Guid id, [FromQuery] DateTime? before, [FromQuery] int limit = 50) =>
            ToActionResult(await _chatService.GetMessagesAsync(User.GetUserId(), id, before, limit));

        [HttpPost("rooms/{id:guid}/messages")]
        public async Task<IActionResult> Send(Guid id, [FromBody] SendMessageRequest request) =>
            ToActionResult(await _chatService.SendAsync(User.GetUserId(), id, request.Content));

        [HttpPost("rooms/{id:guid}/icebreaker")]
        public async Task<IActionResult> AnswerIceBreaker(Guid id, [FromBody] IceBreakerAnswerRequest request) =>
            ToActionResult(await _chatService.AnswerIceBreakerAsync(User.GetUserId(), id, request.Choice));
    }
}
