using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Huy hiệu
    // Mỗi huy hiệu có 1 luật (theo Code) tính từ dữ liệu có sẵn. Không chạy nền: kiểm tra khi người dùng
    // mở app (api/notifications/summary) hoặc xem huy hiệu. Đã nhận thì giữ, không thu hồi.
    // ============================================================
    public class BadgeService : IBadgeService
    {
        private const int MinZoneMembers = 3;
        private const int MinRegionPlayers = 5;

        private readonly BlushDbContext _context;
        private readonly INotificationService _notifications;

        public BadgeService(BlushDbContext context, INotificationService notifications)
        {
            _context = context;
            _notifications = notifications;
        }

        public async Task EvaluateAsync(Guid userId)
        {
            var user = await _context.Users.AsNoTracking().Include(u => u.Profile).FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null || user.RoleId != Role.UserId) return; // huy hiệu dành cho game thủ

            var earned = (await _context.UserBadges.Where(b => b.UserId == userId).Select(b => b.BadgeId).ToListAsync()).ToHashSet();
            var pending = await _context.Badges.AsNoTracking().Where(b => !earned.Contains(b.Id)).ToListAsync();

            foreach (var badge in pending)
            {
                if (!await MeetsAsync(badge.Code, user)) continue;
                var award = new UserBadge { UserId = userId, BadgeId = badge.Id, EarnedAt = DateTime.UtcNow };
                _context.UserBadges.Add(award);
                try
                {
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateException)
                {
                    // 2 request cùng lúc cùng trao 1 huy hiệu -> trùng khóa chính, đã có rồi là được
                    _context.Entry(award).State = EntityState.Detached;
                    continue;
                }
                await _notifications.NotifyAsync(userId, NotificationType.BadgeEarned, $"Nhận huy hiệu mới: {badge.Icon} {badge.NameVI}", badge.Description, "badges");
            }
        }

        public async Task<List<BadgeDto>> GetMineAsync(Guid userId)
        {
            await EvaluateAsync(userId);
            var earned = await _context.UserBadges.Where(b => b.UserId == userId).ToDictionaryAsync(b => b.BadgeId, b => b.EarnedAt);
            var badges = await _context.Badges.AsNoTracking().OrderBy(b => b.Id).ToListAsync();
            return badges
                .Select(b => new BadgeDto
                {
                    Code = b.Code,
                    Name = b.NameVI,
                    Icon = b.Icon,
                    Description = b.Description,
                    Earned = earned.ContainsKey(b.Id),
                    EarnedAt = earned.TryGetValue(b.Id, out var at) ? at : null,
                })
                .OrderByDescending(b => b.Earned)
                .ToList();
        }

        // Luật từng huy hiệu (mô tả trong bảng Badges phải khớp)
        private async Task<bool> MeetsAsync(string code, User user)
        {
            var id = user.Id;
            return code switch
            {
                // Đứng đầu EXP trong 1 Zone Giải trí có từ 3 thành viên đang hoạt động
                BadgeCode.Top1Fun => await _context.UserZones
                    .Where(m => m.UserId == id && _context.Zones.Any(z => z.Id == m.ZoneId && z.Purpose == GamePurpose.Fun))
                    .AnyAsync(m =>
                        _context.UserZones.Count(o => o.ZoneId == m.ZoneId && _context.Users.Any(u => u.Id == o.UserId && u.Status == UserStatus.Active)) >= MinZoneMembers
                        && !_context.UserZones.Any(o => o.ZoneId == m.ZoneId && _context.Users.Any(u => u.Id == o.UserId && u.Status == UserStatus.Active && u.Exp > user.Exp))),

                // Top 3 EXP trong khu vực (cần ít nhất 5 game thủ cùng khu vực)
                BadgeCode.LocalMvp => user.Profile?.Region is string region
                    && await RegionPlayers(region).CountAsync() >= MinRegionPlayers
                    && await RegionPlayers(region).CountAsync(u => u.Exp > user.Exp) < 3,

                // 30 trận Tryhard đã xác nhận cùng đồng đội BLUSH (Nhật ký trận đấu)
                BadgeCode.TryhardKing => await ConfirmedTryhardMatchesAsync(id) >= 30,

                // Có phòng chat mà cả 2 bên đều đã nhắn
                BadgeCode.FirstConnection => await _context.ChatRooms
                    .Where(r => r.User1Id == id || r.User2Id == id)
                    .AnyAsync(r => _context.ChatMessages.Any(m => m.RoomId == r.Id && m.SenderId == r.User1Id)
                        && _context.ChatMessages.Any(m => m.RoomId == r.Id && m.SenderId == r.User2Id)),

                BadgeCode.ZoneStar => await _context.Posts
                    .AnyAsync(p => p.AuthorId == id && p.RemovedAt == null && _context.PostLikes.Count(l => l.PostId == p.Id) >= 10),

                BadgeCode.Friendly => await _context.PostComments.CountAsync(c => c.AuthorId == id && c.RemovedAt == null) >= 20,

                BadgeCode.HardWorker => await _context.UserQuests.CountAsync(q => q.UserId == id && q.CompletedAt != null) >= 10,

                BadgeCode.Supporter => await _context.Transactions.AnyAsync(t => t.UserId == id && t.Status == TransactionStatus.Paid),

                _ => false, // huy hiệu Admin tự thêm vào DB mà chưa có luật: không tự trao
            };
        }

        private IQueryable<User> RegionPlayers(string region) =>
            _context.Users.Where(u => u.RoleId == Role.UserId && u.Status == UserStatus.Active && u.Profile != null
                && u.Profile.Region == region && u.Profile.OnboardingCompletedAt != null);

        // Chưa có Nhật ký trận đấu thì luôn 0
        private static Task<int> ConfirmedTryhardMatchesAsync(Guid userId) => Task.FromResult(0);
    }
}
