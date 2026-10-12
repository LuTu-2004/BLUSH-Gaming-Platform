using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Chặn người dùng
    // Chặn có tác dụng cả 2 chiều (ChatService, RuleBasedMatchingService kiểm tra bảng UserBlocks):
    // không mở/gửi chat, phòng chat cũ bị ẩn, không gợi ý ghép đội với nhau. Người bị chặn không được báo.
    // ============================================================
    public class BlockService : IBlockService
    {
        private readonly BlushDbContext _context;

        public BlockService(BlushDbContext context)
        {
            _context = context;
        }

        public async Task<List<ChatUserDto>> GetBlockedAsync(Guid userId) =>
            await (from b in _context.UserBlocks
                   join u in _context.Users on b.BlockedId equals u.Id
                   where b.BlockerId == userId
                   orderby b.CreatedAt descending
                   select new ChatUserDto
                   {
                       Id = u.Id,
                       DisplayName = u.Profile != null ? u.Profile.DisplayName : "Tài khoản đã xóa",
                       AvatarEmoji = u.Profile != null ? u.Profile.AvatarEmoji : "🎮",
                       AvatarUrl = u.Profile != null ? u.Profile.AvatarUrl : null,
                   })
                .ToListAsync();

        public async Task<ServiceResult<MessageResponse>> BlockAsync(Guid userId, Guid targetId)
        {
            if (targetId == userId)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Bạn không thể tự chặn chính mình.");
            }
            if (!await _context.Users.AnyAsync(u => u.Id == targetId && u.Status != UserStatus.Deleted))
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người chơi!");
            }

            if (!await _context.UserBlocks.AnyAsync(b => b.BlockerId == userId && b.BlockedId == targetId))
            {
                _context.UserBlocks.Add(new UserBlock { BlockerId = userId, BlockedId = targetId, CreatedAt = DateTime.UtcNow });
                try
                {
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateException)
                {
                    // Bấm chặn 2 lần cùng lúc -> trùng khóa chính, đã chặn rồi là được
                }
            }
            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Đã chặn. Hai bạn sẽ không nhắn tin hay được ghép đội với nhau." });
        }

        public async Task<ServiceResult<MessageResponse>> UnblockAsync(Guid userId, Guid targetId)
        {
            await _context.UserBlocks.Where(b => b.BlockerId == userId && b.BlockedId == targetId).ExecuteDeleteAsync();
            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Đã bỏ chặn." });
        }
    }
}
