using Blush.Api.DataAccess;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Service triển khai logic C# .NET
    // Dành cho Backend Dev làm việc với logic nghiệp vụ
    // ============================================================
    public class QuestService : IQuestService
    {
        private readonly BlushDbContext _context;

        public QuestService(BlushDbContext context)
        {
            _context = context;
        }

        public async Task<QuestResultDto> ClaimDailyRewardAsync(string userId)
        {
            // 1. Lấy dữ liệu từ SQL Server qua EF Core (Layer 3)
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                return new QuestResultDto { Success = false, Message = "Không tìm thấy người dùng trong CSDL SQL Server!" };
            }

            // 2. Tính toán nghiệp vụ C#
            int addExp = 50;
            int addCoins = 15;

            user.Exp += addExp;
            user.Coins += addCoins;

            int newLevel = (user.Exp / 100) + 1;
            bool isLeveledUp = newLevel > user.Level;
            user.Level = newLevel;

            // 3. Lưu lại vào SQL Server (Layer 3)
            await _context.SaveChangesAsync();

            return new QuestResultDto
            {
                Success = true,
                Message = isLeveledUp ? $"🎉 Chúc mừng! Bạn đã thăng lên Level {newLevel}!" : "Điểm danh hàng ngày thành công!",
                AddedCoins = addCoins,
                AddedExp = addExp,
                User = user
            };
        }
    }
}
