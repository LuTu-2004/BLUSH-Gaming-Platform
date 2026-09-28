using Blush.Api.DataAccess;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Service triển khai logic nghiệp vụ Quest
    // ============================================================
    public class QuestService : IQuestService
    {
        private const int DailyExp = 50;
        private const int DailyCoins = 15;

        private readonly BlushDbContext _context;
        private readonly IUserService _userService;

        public QuestService(BlushDbContext context, IUserService userService)
        {
            _context = context;
            _userService = userService;
        }

        public async Task<ServiceResult<QuestResultDto>> ClaimDailyRewardAsync(Guid userId)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return ServiceResult<QuestResultDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người dùng!");
            }

            var today = VietnamTime.Today;
            if (user.LastCheckInDate == today)
            {
                return ServiceResult<QuestResultDto>.Fail(StatusCodes.Status400BadRequest, "Hôm nay bạn đã điểm danh rồi!");
            }

            int oldLevel = user.CurrentLevel;
            user.Exp += DailyExp;
            user.Coins += DailyCoins;
            user.LastCheckInDate = today;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(); // SQL tự tính lại CurrentLevel, EF đọc về user.CurrentLevel

            bool isLeveledUp = user.CurrentLevel > oldLevel;
            return ServiceResult<QuestResultDto>.Ok(new QuestResultDto
            {
                Message = isLeveledUp ? $"🎉 Chúc mừng! Bạn đã thăng lên Level {user.CurrentLevel}!" : "Điểm danh hàng ngày thành công!",
                AddedCoins = DailyCoins,
                AddedExp = DailyExp,
                User = (await _userService.GetUserDtoAsync(userId))!,
            });
        }
    }
}
