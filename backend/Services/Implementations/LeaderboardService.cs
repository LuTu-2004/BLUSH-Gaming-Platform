using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Bảng xếp hạng theo tổng EXP
    // Chỉ xếp gamer (role User) đang hoạt động và đã làm khảo sát; lọc theo khu vực và game.
    // ============================================================
    public class LeaderboardService : ILeaderboardService
    {
        public const int MaxLimit = 100;

        private readonly BlushDbContext _context;

        public LeaderboardService(BlushDbContext context)
        {
            _context = context;
        }

        public async Task<ServiceResult<LeaderboardDto>> GetAsync(Guid userId, string? region, int? gameId, int limit)
        {
            if (region != null && !GameCatalog.Regions.Contains(region))
            {
                return ServiceResult<LeaderboardDto>.Fail(StatusCodes.Status400BadRequest, "Khu vực không hợp lệ.");
            }
            limit = Math.Clamp(limit, 1, MaxLimit);

            var ranked = _context.Users.Where(u =>
                u.RoleId == Role.UserId
                && u.Status == UserStatus.Active
                && u.Profile != null
                && u.Profile.OnboardingCompletedAt != null);
            if (region != null) ranked = ranked.Where(u => u.Profile!.Region == region);
            if (gameId != null) ranked = ranked.Where(u => u.GameProfiles.Any(g => g.GameId == gameId));

            var now = DateTime.UtcNow;
            var top = await ToEntries(ranked.OrderByDescending(u => u.Exp).ThenBy(u => u.Profile!.DisplayName).Take(limit), gameId, now)
                .ToListAsync();
            var me = await ToEntries(ranked.Where(u => u.Id == userId), gameId, now).FirstOrDefaultAsync();

            // Hạng = số người nhiều EXP hơn + 1 -> bằng EXP thì cùng hạng
            for (var i = 0; i < top.Count; i++)
            {
                top[i].Rank = i > 0 && top[i].Exp == top[i - 1].Exp ? top[i - 1].Rank : i + 1;
                top[i].IsMe = top[i].UserId == userId;
            }
            if (me != null)
            {
                me.Rank = await ranked.CountAsync(u => u.Exp > me.Exp) + 1;
                me.IsMe = true;
            }

            return ServiceResult<LeaderboardDto>.Ok(new LeaderboardDto { Items = top, Me = me });
        }

        private static IQueryable<LeaderboardEntryDto> ToEntries(IQueryable<User> users, int? gameId, DateTime now) =>
            users.Select(u => new LeaderboardEntryDto
            {
                UserId = u.Id,
                DisplayName = u.Profile!.DisplayName,
                AvatarEmoji = u.Profile.AvatarEmoji,
                AvatarUrl = u.Profile.AvatarUrl,
                Mbti = u.Profile.Mbti,
                Region = u.Profile.Region,
                Level = u.CurrentLevel,
                Exp = u.Exp,
                IsVip = u.Subscriptions.Any(s => s.StartAt <= now && s.EndAt > now),
                GameName = u.GameProfiles
                    .Where(g => gameId == null || g.GameId == gameId)
                    .OrderBy(g => g.GameId)
                    .Select(g => g.Game.GameName)
                    .FirstOrDefault(),
            });
    }
}
