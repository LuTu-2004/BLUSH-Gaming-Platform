using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IBlockService
    {
        /// Người mình đã chặn (để bỏ chặn trong Hồ sơ)
        Task<List<ChatUserDto>> GetBlockedAsync(Guid userId);
        Task<ServiceResult<MessageResponse>> BlockAsync(Guid userId, Guid targetId);
        Task<ServiceResult<MessageResponse>> UnblockAsync(Guid userId, Guid targetId);
    }
}
