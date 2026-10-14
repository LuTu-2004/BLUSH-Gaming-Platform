using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Gợi ý đồng đội bằng cách tính điểm theo trọng số (0-100)
    //
    //   Cùng chơi 1 game ......................... 35
    //   Cùng mục đích trên game chung ............ 15  (Tryhard / Fun / Event)
    //   Trùng khung giờ chơi ..................... 15  (chia theo tỉ lệ khung trùng)
    //   Phong cách chơi (AI đọc phần tự viết) .... 15  (khoảng cách 3 chỉ số tryhard / nói chuyện / tấu hài)
    //   Cùng khu vực ............................. 10
    //   Trùng sở thích ........................... 10  (chia theo tỉ lệ sở thích trùng)
    //
    // Ai chưa chọn khung giờ / sở thích / chưa viết gì để AI phân tích thì được nửa số điểm mục đó (không biết thì không phạt).
    // Chỉ xét người có ít nhất 1 game chung, nên điểm game luôn là 35.
    // ============================================================
    public class RuleBasedMatchingService : IMatchingService
    {
        public const int GameWeight = 35;
        public const int PurposeWeight = 15;
        public const int PlayTimeWeight = 15;
        public const int PlaystyleWeight = 15;
        public const int RegionWeight = 10;
        public const int HobbyWeight = 10;

        // Số ứng viên tối đa lấy từ DB để chấm điểm (đủ cho quy mô hiện tại)
        private const int MaxCandidates = 300;

        private static readonly Dictionary<string, string> ShortSlotLabels = new()
        {
            [PlayTimeSlot.Morning] = "buổi sáng",
            [PlayTimeSlot.Afternoon] = "buổi chiều",
            [PlayTimeSlot.Evening] = "buổi tối",
            [PlayTimeSlot.LateNight] = "khuya",
            [PlayTimeSlot.Weekend] = "cuối tuần",
        };

        private readonly BlushDbContext _context;

        public RuleBasedMatchingService(BlushDbContext context)
        {
            _context = context;
        }

        public async Task<ServiceResult<List<MatchSuggestionDto>>> GetSuggestionsAsync(Guid userId, int? gameId, int limit)
        {
            var me = await ToPlayerData(_context.Users.Where(u => u.Id == userId)).FirstOrDefaultAsync();
            if (me == null || !me.OnboardingCompleted)
            {
                return ServiceResult<List<MatchSuggestionDto>>.Fail(
                    StatusCodes.Status400BadRequest, "Bạn cần hoàn tất khảo sát sở thích trước khi ghép đội.", ErrorCodes.OnboardingRequired);
            }

            var gameIds = gameId.HasValue ? new List<int> { gameId.Value } : me.Games.Select(g => g.GameId).ToList();
            var now = DateTime.UtcNow;

            var candidateUsers = _context.Users.Where(u =>
                u.Id != userId
                && u.RoleId == Role.UserId
                && u.Status == UserStatus.Active
                && u.EmailConfirmed
                && u.Profile!.OnboardingCompletedAt != null
                && u.GameProfiles.Any(g => gameIds.Contains(g.GameId))
                // Đã chặn nhau (chiều nào cũng vậy) thì không gợi ý
                && !_context.UserBlocks.Any(b => (b.BlockerId == userId && b.BlockedId == u.Id) || (b.BlockerId == u.Id && b.BlockedId == userId)));
            var candidates = await ToPlayerData(candidateUsers).Take(MaxCandidates).ToListAsync();

            var vipIds = await _context.UserSubscriptions
                .Where(s => s.StartAt <= now && s.EndAt > now)
                .Select(s => s.UserId)
                .Distinct()
                .ToListAsync();

            var today = VietnamTime.Today;
            var result = candidates
                .Select(c => Score(me, c, gameId, vipIds.Contains(c.UserId), today))
                .OrderByDescending(s => s.Score)
                .ThenByDescending(s => s.IsVip) // VIP được ưu tiên khi bằng điểm
                .Take(Math.Clamp(limit, 1, 50))
                .ToList();

            return ServiceResult<List<MatchSuggestionDto>>.Ok(result);
        }

        private static MatchSuggestionDto Score(PlayerData me, PlayerData other, int? gameId, bool isVip, DateOnly today)
        {
            var myGames = me.Games.ToDictionary(g => g.GameId);
            var shared = other.Games
                .Where(g => gameId.HasValue ? g.GameId == gameId.Value : myGames.ContainsKey(g.GameId))
                .ToList();

            // Game hiển thị: ưu tiên game chung mà 2 người cùng mục đích
            var samePurposeGame = shared.FirstOrDefault(g => myGames.TryGetValue(g.GameId, out var mine) && mine.Purpose == g.Purpose);
            var shown = samePurposeGame ?? shared.First();

            int score = GameWeight;
            var reasons = new List<string> { $"Cùng chơi {shown.GameName}" };

            if (samePurposeGame != null)
            {
                score += PurposeWeight;
                reasons.Add("cùng mục tiêu " + GameCatalog.PurposeLabel(samePurposeGame.Purpose!).ToLowerInvariant());
            }

            var commonSlots = me.PlayTimes.Intersect(other.PlayTimes).ToList();
            score += Overlap(me.PlayTimes.Count, other.PlayTimes.Count, commonSlots.Count, PlayTimeWeight);
            if (commonSlots.Count > 0)
            {
                reasons.Add("cùng hay chơi " + string.Join(", ", commonSlots.Select(s => ShortSlotLabels[s])));
            }

            if (me.Region != null && me.Region == other.Region)
            {
                score += RegionWeight;
                reasons.Add($"cùng ở {GameCatalog.RegionLabel(me.Region)}");
            }

            var (playstylePoints, playstyleReason) = Playstyle(me, other);
            score += playstylePoints;
            if (playstyleReason != null) reasons.Add(playstyleReason);

            var commonHobbies = me.Hobbies.Intersect(other.Hobbies).ToList();
            score += Overlap(me.Hobbies.Count, other.Hobbies.Count, commonHobbies.Count, HobbyWeight);
            if (commonHobbies.Count > 0)
            {
                reasons.Add("cùng thích " + string.Join(", ", commonHobbies.Take(2)));
            }

            return new MatchSuggestionDto
            {
                UserId = other.UserId,
                DisplayName = other.DisplayName,
                AvatarEmoji = other.AvatarEmoji,
                AvatarUrl = other.AvatarUrl,
                Age = AgeOf(other.DateOfBirth, today),
                Mbti = other.Mbti,
                Bio = other.Bio,
                Region = other.Region,
                UsesMic = other.UsesMic,
                IsVip = isVip,
                GameId = shown.GameId,
                GameName = shown.GameName,
                Position = shown.Position,
                Purpose = shown.Purpose,
                Hobbies = other.Hobbies,
                Score = Math.Min(score, 100),
                Reason = string.Join(" · ", reasons),
            };
        }

        /// Phong cách chơi: càng gần nhau (3 chỉ số -2..2) càng nhiều điểm. Hợp nhiều thì nêu điểm chung nổi bật.
        private static (int Points, string? Reason) Playstyle(PlayerData me, PlayerData other)
        {
            if (me.Playstyle is not { } a || other.Playstyle is not { } b) return (PlaystyleWeight / 2, null);

            var distance = Math.Sqrt(Math.Pow(a.Competitive - b.Competitive, 2) + Math.Pow(a.Social - b.Social, 2) + Math.Pow(a.Humor - b.Humor, 2));
            var similarity = 1 - distance / Math.Sqrt(3 * 16); // 4 = khoảng cách xa nhất của 1 chỉ số (-2 -> 2)
            var points = (int)Math.Round(PlaystyleWeight * similarity);
            if (similarity < 0.7) return (points, null);

            var shared = new List<string>();
            if (a.Competitive <= -1 && b.Competitive <= -1) shared.Add("chơi chill");
            if (a.Competitive >= 1 && b.Competitive >= 1) shared.Add("nghiêm túc leo rank");
            if (a.Social >= 1 && b.Social >= 1) shared.Add("thích bật mic trò chuyện");
            if (a.Social <= -1 && b.Social <= -1) shared.Add("thích tập trung, ít nói");
            if (a.Humor >= 1 && b.Humor >= 1) shared.Add("mê tấu hài");
            return (points, shared.Count == 0 ? "hợp phong cách chơi" : "cùng " + string.Join(", ", shared.Take(2)));
        }

        /// Điểm theo tỉ lệ trùng: trùng hết các lựa chọn của người chọn ít hơn = đủ điểm.
        /// Một trong 2 người chưa chọn gì = nửa điểm.
        private static int Overlap(int mine, int theirs, int common, int weight)
        {
            if (mine == 0 || theirs == 0) return weight / 2;
            return (int)Math.Round(weight * (double)common / Math.Min(mine, theirs));
        }

        private static int? AgeOf(DateOnly? dob, DateOnly today)
        {
            if (dob == null) return null;
            var age = today.Year - dob.Value.Year;
            return dob.Value > today.AddYears(-age) ? age - 1 : age;
        }

        // Lấy đủ dữ liệu ghép đội của người chơi trong 1 câu truy vấn
        private static IQueryable<PlayerData> ToPlayerData(IQueryable<User> users) =>
            users.AsNoTracking()
                .Where(u => u.Profile != null)
                .Select(u => new PlayerData
                {
                    UserId = u.Id,
                    OnboardingCompleted = u.Profile!.OnboardingCompletedAt != null,
                    DisplayName = u.Profile.DisplayName,
                    AvatarEmoji = u.Profile.AvatarEmoji,
                    AvatarUrl = u.Profile.AvatarUrl,
                    DateOfBirth = u.Profile.DateOfBirth,
                    Mbti = u.Profile.Mbti,
                    Bio = u.Profile.Bio,
                    Region = u.Profile.Region,
                    UsesMic = u.Profile.UsesMic,
                    PlayCompetitive = u.Profile.PlayCompetitive,
                    PlaySocial = u.Profile.PlaySocial,
                    PlayHumor = u.Profile.PlayHumor,
                    Games = u.GameProfiles.Select(g => new PlayerGame
                    {
                        GameId = g.GameId,
                        GameName = g.Game.GameName,
                        Position = g.PreferredPosition,
                        Purpose = g.Purpose,
                    }).ToList(),
                    PlayTimes = u.PlayTimes.Select(t => t.Slot).ToList(),
                    Hobbies = u.Hobbies.Select(h => h.Hobby.Name).ToList(),
                });

        private class PlayerData
        {
            public Guid UserId { get; set; }
            public bool OnboardingCompleted { get; set; }
            public string DisplayName { get; set; } = string.Empty;
            public string AvatarEmoji { get; set; } = "🎮";
            public string? AvatarUrl { get; set; }
            public DateOnly? DateOfBirth { get; set; }
            public string? Mbti { get; set; }
            public string? Bio { get; set; }
            public string? Region { get; set; }
            public bool? UsesMic { get; set; }
            public short? PlayCompetitive { get; set; }
            public short? PlaySocial { get; set; }
            public short? PlayHumor { get; set; }
            public List<PlayerGame> Games { get; set; } = new();

            // Đủ 3 chỉ số mới so sánh (chưa phân tích thì null)
            public (int Competitive, int Social, int Humor)? Playstyle =>
                PlayCompetitive is short c && PlaySocial is short s && PlayHumor is short h ? (c, s, h) : null;
            public List<string> PlayTimes { get; set; } = new();
            public List<string> Hobbies { get; set; } = new();
        }

        private class PlayerGame
        {
            public int GameId { get; set; }
            public string GameName { get; set; } = string.Empty;
            public string? Position { get; set; }
            public string? Purpose { get; set; }
        }
    }
}
