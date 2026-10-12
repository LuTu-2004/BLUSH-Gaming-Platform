using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Service triển khai logic nghiệp vụ Quest
    // Tiến độ lưu ở UserQuests theo từng kỳ (QuestType.PeriodStartOf): sang ngày/tuần/mùa mới thì bắt đầu lại từ 0.
    // ============================================================
    public class QuestService : IQuestService
    {
        private const int DailyExp = 50;
        private const int DailyCoins = 15;

        private readonly BlushDbContext _context;
        private readonly IUserService _userService;
        private readonly INotificationService _notifications;

        public QuestService(BlushDbContext context, IUserService userService, INotificationService notifications)
        {
            _context = context;
            _userService = userService;
            _notifications = notifications;
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

            user.LastCheckInDate = today;
            return ServiceResult<QuestResultDto>.Ok(await AddRewardAsync(user, DailyExp, DailyCoins, "Điểm danh hàng ngày thành công!"));
        }

        public async Task<List<QuestDto>> GetQuestsAsync(Guid userId)
        {
            var today = VietnamTime.Today;
            var quests = await _context.Quests.AsNoTracking().Where(q => q.IsActive).OrderBy(q => q.Id).ToListAsync();

            var periodStarts = quests.Select(q => QuestType.PeriodStartOf(q.QuestType, today)).Distinct().ToList();
            var progress = await _context.UserQuests.AsNoTracking()
                .Where(uq => uq.UserId == userId && periodStarts.Contains(uq.PeriodStart))
                .ToListAsync();

            return quests.Select(q =>
            {
                var periodStart = QuestType.PeriodStartOf(q.QuestType, today);
                var uq = progress.FirstOrDefault(p => p.QuestId == q.Id && p.PeriodStart == periodStart);
                return new QuestDto
                {
                    Id = q.Id,
                    Code = q.Code,
                    Title = q.TitleVI,
                    Description = q.DescVI,
                    Type = q.QuestType,
                    Target = q.TargetCount,
                    Current = uq?.CurrentProgress ?? 0,
                    RewardCoins = q.RewardCoins,
                    RewardExp = q.RewardExp,
                    IsCompleted = uq?.CompletedAt != null,
                    IsClaimed = uq?.ClaimedAt != null,
                    PeriodStart = periodStart,
                };
            }).ToList();
        }

        public async Task<ServiceResult<QuestResultDto>> ClaimQuestAsync(Guid userId, int questId)
        {
            var quest = await _context.Quests.AsNoTracking().FirstOrDefaultAsync(q => q.Id == questId && q.IsActive);
            if (quest == null)
            {
                return ServiceResult<QuestResultDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy nhiệm vụ!");
            }
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return ServiceResult<QuestResultDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người dùng!");
            }

            var periodStart = QuestType.PeriodStartOf(quest.QuestType, VietnamTime.Today);
            var row = _context.UserQuests.Where(uq => uq.UserId == userId && uq.QuestId == questId && uq.PeriodStart == periodStart);

            // Đánh dấu "đã nhận" bằng 1 câu UPDATE có điều kiện: bấm 2 lần cùng lúc thì chỉ 1 lần được cộng quà
            await using var transaction = await _context.Database.BeginTransactionAsync();
            var claimed = await row.Where(uq => uq.CompletedAt != null && uq.ClaimedAt == null)
                .ExecuteUpdateAsync(s => s.SetProperty(uq => uq.ClaimedAt, DateTime.UtcNow));
            if (claimed == 0)
            {
                var alreadyClaimed = await row.AnyAsync(uq => uq.ClaimedAt != null);
                return ServiceResult<QuestResultDto>.Fail(StatusCodes.Status400BadRequest,
                    alreadyClaimed ? "Bạn đã nhận quà nhiệm vụ này rồi!" : "Nhiệm vụ chưa hoàn thành!");
            }

            var result = await AddRewardAsync(user, quest.RewardExp, quest.RewardCoins, $"Hoàn thành nhiệm vụ \"{quest.TitleVI}\"!");
            await transaction.CommitAsync();
            return ServiceResult<QuestResultDto>.Ok(result);
        }

        public async Task SetProgressAtLeastAsync(Guid userId, string questCode, int value)
        {
            var quest = await _context.Quests.AsNoTracking().FirstOrDefaultAsync(q => q.Code == questCode && q.IsActive);
            if (quest == null || value <= 0) return;
            var periodStart = QuestType.PeriodStartOf(quest.QuestType, VietnamTime.Today);
            var current = await _context.UserQuests.Where(uq => uq.UserId == userId && uq.QuestId == quest.Id && uq.PeriodStart == periodStart)
                .Select(uq => (int?)uq.CurrentProgress).FirstOrDefaultAsync() ?? 0;
            if (value > current) await RecordProgressAsync(userId, questCode, value - current);
        }

        public async Task RecordProgressAsync(Guid userId, string questCode, int amount = 1)
        {
            var quest = await _context.Quests.AsNoTracking().FirstOrDefaultAsync(q => q.Code == questCode && q.IsActive);
            if (quest == null) return; // Admin tắt nhiệm vụ -> không đếm

            var periodStart = QuestType.PeriodStartOf(quest.QuestType, VietnamTime.Today);
            var row = await _context.UserQuests
                .FirstOrDefaultAsync(uq => uq.UserId == userId && uq.QuestId == quest.Id && uq.PeriodStart == periodStart);
            if (row?.CompletedAt != null) return;

            if (row == null)
            {
                row = new UserQuest { Id = Guid.NewGuid(), UserId = userId, QuestId = quest.Id, PeriodStart = periodStart };
                _context.UserQuests.Add(row);
            }
            row.CurrentProgress = Math.Min(row.CurrentProgress + amount, quest.TargetCount);
            if (row.CurrentProgress >= quest.TargetCount) row.CompletedAt = DateTime.UtcNow;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // 2 request cùng lúc cùng tạo dòng mới -> trùng UQ_UserQuests_Period. Bỏ qua lần đếm này.
                _context.Entry(row).State = EntityState.Detached;
                return;
            }
            if (row.CompletedAt != null)
            {
                await _notifications.NotifyAsync(userId, NotificationType.QuestCompleted, $"Hoàn thành nhiệm vụ: {quest.TitleVI}",
                    $"Vào Nhiệm vụ để nhận +{quest.RewardCoins} Coins, +{quest.RewardExp} EXP.", "quests");
            }
        }

        private async Task<QuestResultDto> AddRewardAsync(User user, int exp, int coins, string message)
        {
            int oldLevel = user.CurrentLevel;
            user.Exp += exp;
            user.Coins += coins;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(); // SQL tự tính lại CurrentLevel, EF đọc về user.CurrentLevel

            bool isLeveledUp = user.CurrentLevel > oldLevel;
            return new QuestResultDto
            {
                Message = isLeveledUp ? $"🎉 Chúc mừng! Bạn đã thăng lên Level {user.CurrentLevel}!" : message,
                AddedCoins = coins,
                AddedExp = exp,
                User = (await _userService.GetUserDtoAsync(user.Id))!,
            };
        }
    }
}
