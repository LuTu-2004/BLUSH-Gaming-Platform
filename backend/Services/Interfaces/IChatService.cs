using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // Chat 1-1. Gửi qua REST, nhận thời gian thực qua SignalR (Hubs/ChatHub, sự kiện "message" và "room").
    public interface IChatService
    {
        Task<List<ChatRoomDto>> GetRoomsAsync(Guid userId);

        /// Mở phòng với [otherUserId]: đã có thì trả phòng cũ, chưa có thì tạo + gắn 1 câu hỏi phá băng ngẫu nhiên
        Task<ServiceResult<ChatRoomDto>> OpenRoomAsync(Guid userId, Guid otherUserId);
        Task<ServiceResult<ChatRoomDto>> GetRoomAsync(Guid userId, Guid roomId);

        /// Tin cũ hơn [before] (null = mới nhất), trả về theo thứ tự cũ -> mới
        Task<ServiceResult<List<ChatMessageDto>>> GetMessagesAsync(Guid userId, Guid roomId, DateTime? before, int limit);
        Task<ServiceResult<ChatMessageDto>> SendAsync(Guid userId, Guid roomId, string content);
        Task<ServiceResult<ChatRoomDto>> AnswerIceBreakerAsync(Guid userId, Guid roomId, string choice);
    }
}
