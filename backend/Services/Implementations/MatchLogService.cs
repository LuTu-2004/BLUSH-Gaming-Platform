using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Nhật ký trận đấu + rank tự khai
    //   Ghi trận: chỉ với người mình đã chat (đồng đội BLUSH thật), không chặn nhau, tối đa 20 trận/ngày
    //   Đồng đội xác nhận -> cả 2 được tính: "Chơi 3 trận cùng nhóm BLUSH", chuỗi thắng tuần, hỗ trợ tân thủ
    //   Khai rank Cao Thủ (hoặc tương đương) -> nhiệm vụ mùa "Đạt rank Cao Thủ"
    // ============================================================
    public class MatchLogService : IMatchLogService
    {
        public const int MaxPerDay = 20;
        public const int NewbieMaxLevel = 5;
        private const int HistorySize = 50;

        private readonly BlushDbContext _context;
        private readonly IQuestService _quests;
        private readonly INotificationService _notifications;

        public MatchLogService(BlushDbContext context, IQuestService quests, INotificationService notifications)
        {
            _context = context;
            _quests = quests;
            _notifications = notifications;
        }

        public async Task<MatchOptionsDto> GetOptionsAsync(Guid userId)
        {
            var teammateIds = await ChatPartners(userId).ToListAsync();
            var teammates = await _context.Users.AsNoTracking()
                .Where(u => teammateIds.Contains(u.Id) && u.Status == UserStatus.Active && u.Profile != null)
                .Select(u => new ChatUserDto { Id = u.Id, DisplayName = u.Profile!.DisplayName, AvatarEmoji = u.Profile.AvatarEmoji, AvatarUrl = u.Profile.AvatarUrl })
                .OrderBy(u => u.DisplayName)
                .ToListAsync();

            var games = await _context.UserGameProfiles.AsNoTracking()
                .Where(g => g.UserId == userId)
                .Select(g => new { g.GameId, g.Game.GameName, g.Rank })
                .ToListAsync();

            return new MatchOptionsDto
            {
                Teammates = teammates,
                Games = games.Select(g => new GameRankDto { GameId = g.GameId, GameName = g.GameName, Rank = g.Rank, Ranks = GameCatalog.RanksOf(g.GameName) }).ToList(),
            };
        }

        public async Task<List<MatchLogDto>> GetMineAsync(Guid userId)
        {
            var matches = await _context.Matches.AsNoTracking().Include(m => m.Game)
                .Where(m => m.ReporterId == userId || m.TeammateId == userId)
                .OrderByDescending(m => m.Status == MatchStatus.Pending && m.TeammateId == userId)
                .ThenByDescending(m => m.CreatedAt)
                .Take(HistorySize)
                .ToListAsync();
            var users = await LoadUsersAsync(matches.SelectMany(m => new[] { m.ReporterId, m.TeammateId }));
            return matches.Select(m => ToDto(m, userId, users)).ToList();
        }

        public async Task<ServiceResult<MatchLogDto>> CreateAsync(Guid userId, CreateMatchRequest request)
        {
            var teammateId = request.TeammateId!.Value;
            if (teammateId == userId) return Fail(StatusCodes.Status400BadRequest, "Hãy chọn đồng đội khác bạn.");
            if (!await ChatPartners(userId).AnyAsync(id => id == teammateId))
            {
                return Fail(StatusCodes.Status400BadRequest, "Chỉ ghi trận với đồng đội bạn đã trò chuyện trên BLUSH.");
            }
            if (!await _context.Users.AnyAsync(u => u.Id == teammateId && u.Status == UserStatus.Active))
            {
                return Fail(StatusCodes.Status404NotFound, "Không tìm thấy người chơi!");
            }
            var game = await _context.Games.AsNoTracking().FirstOrDefaultAsync(g => g.Id == request.GameId && g.IsActive);
            if (game == null) return Fail(StatusCodes.Status400BadRequest, "Game không hợp lệ.");

            var dayStart = VietnamTime.Today.ToDateTime(TimeOnly.MinValue).AddHours(-7);
            if (await _context.Matches.CountAsync(m => m.ReporterId == userId && m.CreatedAt >= dayStart) >= MaxPerDay)
            {
                return Fail(StatusCodes.Status429TooManyRequests, $"Mỗi ngày chỉ ghi được {MaxPerDay} trận.");
            }

            var match = new MatchLog
            {
                Id = Guid.NewGuid(),
                ReporterId = userId,
                TeammateId = teammateId,
                GameId = game.Id,
                Result = request.Result,
                Status = MatchStatus.Pending,
                CreatedAt = DateTime.UtcNow,
            };
            _context.Matches.Add(match);
            await _context.SaveChangesAsync();

            var reporterName = await DisplayNameAsync(userId);
            await _notifications.NotifyAsync(teammateId, NotificationType.MatchToConfirm,
                $"{reporterName} ghi trận {game.GameName} ({ResultLabel(match.Result)}) cùng bạn",
                "Xác nhận nếu đúng là hai bạn vừa chơi cùng nhau.", "matches");

            match.Game = game;
            var users = await LoadUsersAsync(new[] { userId, teammateId });
            return ServiceResult<MatchLogDto>.Ok(ToDto(match, userId, users));
        }

        public async Task<ServiceResult<MatchLogDto>> ConfirmAsync(Guid userId, Guid matchId, bool confirm)
        {
            var now = DateTime.UtcNow;
            // UPDATE có điều kiện: bấm 2 lần cùng lúc thì chỉ 1 lần được tính
            var updated = await _context.Matches
                .Where(m => m.Id == matchId && m.TeammateId == userId && m.Status == MatchStatus.Pending)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(m => m.Status, confirm ? MatchStatus.Confirmed : MatchStatus.Rejected)
                    .SetProperty(m => m.ConfirmedAt, confirm ? now : (DateTime?)null));
            if (updated == 0) return Fail(StatusCodes.Status404NotFound, "Không tìm thấy trận đang chờ bạn xác nhận!");

            var match = await _context.Matches.AsNoTracking().Include(m => m.Game).FirstAsync(m => m.Id == matchId);
            if (confirm)
            {
                await CountForQuestsAsync(match);
                await _notifications.NotifyAsync(match.ReporterId, NotificationType.MatchConfirmed,
                    $"{await DisplayNameAsync(userId)} đã xác nhận trận {match.Game.GameName}", "Trận đã được tính vào nhiệm vụ của hai bạn.", "matches");
            }

            var users = await LoadUsersAsync(new[] { match.ReporterId, match.TeammateId });
            return ServiceResult<MatchLogDto>.Ok(ToDto(match, userId, users));
        }

        public async Task<ServiceResult<GameRankDto>> SetRankAsync(Guid userId, int gameId, string? rank)
        {
            var profile = await _context.UserGameProfiles.Include(g => g.Game).FirstOrDefaultAsync(g => g.UserId == userId && g.GameId == gameId);
            if (profile == null)
            {
                return ServiceResult<GameRankDto>.Fail(StatusCodes.Status400BadRequest, "Thêm game này trong Sở thích chơi game trước.");
            }
            var ranks = GameCatalog.RanksOf(profile.Game.GameName);
            rank = string.IsNullOrWhiteSpace(rank) ? null : rank.Trim();
            if (rank != null && !ranks.Contains(rank))
            {
                return ServiceResult<GameRankDto>.Fail(StatusCodes.Status400BadRequest, "Rank không hợp lệ.");
            }

            profile.Rank = rank;
            profile.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            if (rank != null && GameCatalog.IsMasterOrAbove(profile.Game.GameName, rank))
            {
                await _quests.SetProgressAtLeastAsync(userId, QuestCode.SeasonMasterRank, 1);
            }
            return ServiceResult<GameRankDto>.Ok(new GameRankDto { GameId = gameId, GameName = profile.Game.GameName, Rank = rank, Ranks = ranks });
        }

        // ─────────────────────────── HÀM DÙNG CHUNG ───────────────────────────

        // Trận vừa được xác nhận -> nhiệm vụ của cả 2 người
        private async Task CountForQuestsAsync(MatchLog match)
        {
            var levels = await _context.Users.Where(u => u.Id == match.ReporterId || u.Id == match.TeammateId)
                .Select(u => new { u.Id, u.CurrentLevel }).ToDictionaryAsync(u => u.Id, u => u.CurrentLevel);

            foreach (var (player, other) in new[] { (match.ReporterId, match.TeammateId), (match.TeammateId, match.ReporterId) })
            {
                await _quests.RecordProgressAsync(player, QuestCode.DailyPlayTeam);
                await _quests.SetProgressAtLeastAsync(player, QuestCode.WeeklyWinStreak, Math.Min(await WinStreakThisWeekAsync(player), 3));
                // Hỗ trợ tân thủ: đồng đội Level <= 5 và mình level cao hơn
                if (levels.GetValueOrDefault(other) <= NewbieMaxLevel && levels.GetValueOrDefault(player) > levels.GetValueOrDefault(other))
                {
                    await _quests.RecordProgressAsync(player, QuestCode.WeeklyHelpNewbie);
                }
            }
        }

        // Số trận thắng liên tiếp gần nhất (đã xác nhận, trong tuần này)
        private async Task<int> WinStreakThisWeekAsync(Guid userId)
        {
            var weekStart = QuestType.PeriodStartOf(QuestType.Weekly, VietnamTime.Today).ToDateTime(TimeOnly.MinValue).AddHours(-7);
            var results = await _context.Matches
                .Where(m => m.Status == MatchStatus.Confirmed && m.ConfirmedAt >= weekStart && (m.ReporterId == userId || m.TeammateId == userId))
                .OrderByDescending(m => m.ConfirmedAt)
                .Select(m => m.Result)
                .ToListAsync();
            return results.TakeWhile(r => r == MatchResult.Win).Count();
        }

        // Người đã có phòng chat với mình (không tính người đã chặn nhau)
        private IQueryable<Guid> ChatPartners(Guid userId) =>
            _context.ChatRooms
                .Where(r => (r.User1Id == userId || r.User2Id == userId)
                    && !_context.UserBlocks.Any(b => (b.BlockerId == r.User1Id && b.BlockedId == r.User2Id) || (b.BlockerId == r.User2Id && b.BlockedId == r.User1Id)))
                .Select(r => r.User1Id == userId ? r.User2Id : r.User1Id);

        private async Task<Dictionary<Guid, ChatUserDto>> LoadUsersAsync(IEnumerable<Guid> ids)
        {
            var list = ids.Distinct().ToList();
            return await _context.Users.AsNoTracking().Where(u => list.Contains(u.Id))
                .Select(u => new ChatUserDto
                {
                    Id = u.Id,
                    DisplayName = u.Profile != null ? u.Profile.DisplayName : "Tài khoản đã xóa",
                    AvatarEmoji = u.Profile != null ? u.Profile.AvatarEmoji : "🎮",
                    AvatarUrl = u.Profile != null ? u.Profile.AvatarUrl : null,
                })
                .ToDictionaryAsync(u => u.Id);
        }

        private async Task<string> DisplayNameAsync(Guid userId) =>
            await _context.UserProfiles.Where(p => p.UserId == userId).Select(p => p.DisplayName).FirstOrDefaultAsync() ?? "Đồng đội";

        private static string ResultLabel(string result) => result == MatchResult.Win ? "Thắng" : "Thua";

        private static MatchLogDto ToDto(MatchLog m, Guid viewerId, Dictionary<Guid, ChatUserDto> users) => new()
        {
            Id = m.Id,
            GameName = m.Game.GameName,
            Result = m.Result,
            Status = m.Status,
            Reporter = users.GetValueOrDefault(m.ReporterId) ?? new ChatUserDto { Id = m.ReporterId, DisplayName = "Tài khoản đã xóa" },
            Teammate = users.GetValueOrDefault(m.TeammateId) ?? new ChatUserDto { Id = m.TeammateId, DisplayName = "Tài khoản đã xóa" },
            CanConfirm = m.Status == MatchStatus.Pending && m.TeammateId == viewerId,
            CreatedAt = m.CreatedAt,
        };

        private static ServiceResult<MatchLogDto> Fail(int status, string message) => ServiceResult<MatchLogDto>.Fail(status, message);
    }
}
