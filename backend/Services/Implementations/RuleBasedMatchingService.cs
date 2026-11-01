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
    //   Cùng chơi 1 game ......................... 30
    //   Rank gần nhau trên game hiển thị ......... 5   (lệch 0-1 bậc: đủ, lệch 2: nửa, xa hơn: 0)
    //   Cùng mục đích trên game chung ............ 15  (Tryhard / Fun / Event)
    //   Trùng khung giờ chơi ..................... 15  (chia theo tỉ lệ khung trùng)
    //   Phong cách chơi .......................... 15  (trung bình các tín hiệu 2 người cùng có: vai trò trong team,
    //                                                    mức nói chuyện, kiểu nói chuyện, 3 chỉ số AI đọc phần tự viết)
    //   Cùng khu vực ............................. 10  (cùng tỉnh/thành; khác tỉnh nhưng cùng miền được 5)
    //   Trùng sở thích ........................... 10  (chia theo tỉ lệ sở thích trùng)
    //
    // Ai chưa chọn khung giờ / sở thích / phong cách chơi thì được nửa số điểm mục đó (không biết thì không phạt).
    // Chỉ xét người có ít nhất 1 game chung, nên điểm game luôn là 30.
    // ============================================================
    public class RuleBasedMatchingService : IMatchingService
    {
        public const int GameWeight = 30;
        public const int RankWeight = 5;
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

            var (rankPoints, rankReason) = RankCloseness(myGames.GetValueOrDefault(shown.GameId), shown);
            score += rankPoints;
            if (rankReason != null) reasons.Add(rankReason);

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
            else if (me.Region != null && other.Region != null && GameCatalog.ZoneOf(me.Region) is string zone
                && zone != GameCatalog.Overseas && zone == GameCatalog.ZoneOf(other.Region))
            {
                score += RegionWeight / 2;
                reasons.Add($"cùng {GameCatalog.ZoneLabel(zone).ToLowerInvariant()}");
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

        /// Phong cách chơi: mỗi tín hiệu cả 2 cùng có cho độ hợp 0..1, điểm = trung bình. Không có tín hiệu nào = nửa điểm.
        /// Hợp nhiều thì nêu điểm chung nổi bật.
        private static (int Points, string? Reason) Playstyle(PlayerData me, PlayerData other)
        {
            var signals = new List<double>();
            var shared = new List<string>();

            // Vai trò: 2 người cùng muốn cầm trịch / cùng muốn gánh thì dễ giẫm chân nhau
            if (me.TeamRole != null && other.TeamRole != null)
            {
                var sameLead = me.TeamRole == other.TeamRole && me.TeamRole is "Shotcaller" or "Carry";
                signals.Add(sameLead ? 0.5 : 1);
                if (me.TeamRole != other.TeamRole && me.TeamRole != PlaystyleChoices.Flex && other.TeamRole != PlaystyleChoices.Flex)
                {
                    shared.Add("vai trò bổ trợ nhau");
                }
            }

            // Mức nói chuyện, kiểu nói chuyện: có thứ tự, lệch càng xa càng ít điểm
            int myTalk = PlaystyleChoices.IndexOf(PlaystyleChoices.TalkLevels, me.TalkLevel);
            int theirTalk = PlaystyleChoices.IndexOf(PlaystyleChoices.TalkLevels, other.TalkLevel);
            var bothTalk = myTalk >= 0 && theirTalk >= 0;
            if (bothTalk)
            {
                signals.Add(1 - Math.Abs(myTalk - theirTalk) / 2.0);
                if (myTalk == theirTalk && myTalk != 1) shared.Add(myTalk == 0 ? "thích tập trung, ít nói" : "thích vừa chơi vừa tám");
            }
            int myBanter = PlaystyleChoices.IndexOf(PlaystyleChoices.BanterLevels, me.BanterLevel);
            int theirBanter = PlaystyleChoices.IndexOf(PlaystyleChoices.BanterLevels, other.BanterLevel);
            if (myBanter >= 0 && theirBanter >= 0)
            {
                signals.Add(1 - Math.Abs(myBanter - theirBanter) / 2.0);
                if (myBanter == theirBanter && myBanter != 1) shared.Add(myBanter == 0 ? "nói chuyện nhẹ nhàng" : "thích cà khịa");
            }

            // 3 chỉ số AI đọc phần tự viết (-2..2)
            if (me.Playstyle is { } a && other.Playstyle is { } b)
            {
                var distance = Math.Sqrt(Math.Pow(a.Competitive - b.Competitive, 2) + Math.Pow(a.Social - b.Social, 2) + Math.Pow(a.Humor - b.Humor, 2));
                signals.Add(1 - distance / Math.Sqrt(3 * 16)); // 4 = khoảng cách xa nhất của 1 chỉ số (-2 -> 2)
                if (a.Competitive <= -1 && b.Competitive <= -1) shared.Add("chơi chill");
                if (a.Competitive >= 1 && b.Competitive >= 1) shared.Add("nghiêm túc leo rank");
                // Đã tự chọn mức nói chuyện thì tin câu trả lời hơn AI
                if (!bothTalk && a.Social >= 1 && b.Social >= 1) shared.Add("thích bật mic trò chuyện");
                if (!bothTalk && a.Social <= -1 && b.Social <= -1) shared.Add("thích tập trung, ít nói");
                if (a.Humor >= 1 && b.Humor >= 1) shared.Add("mê tấu hài");
            }

            if (signals.Count == 0) return (PlaystyleWeight / 2, null);
            var similarity = signals.Average();
            var points = (int)Math.Round(PlaystyleWeight * similarity);
            if (similarity < 0.7) return (points, null);
            return (points, shared.Count == 0 ? "hợp phong cách chơi" : "cùng " + string.Join(", ", shared.Take(2)));
        }

        /// Rank 2 người trên cùng 1 game: lệch 0-1 bậc đủ điểm, lệch 2 bậc nửa điểm. Thiếu rank = nửa điểm.
        private static (int Points, string? Reason) RankCloseness(PlayerGame? mine, PlayerGame theirs)
        {
            if (mine?.Rank == null || theirs.Rank == null) return (RankWeight / 2, null);
            var ranks = GameCatalog.RanksOf(theirs.GameName);
            int a = ranks.IndexOf(mine.Rank), b = ranks.IndexOf(theirs.Rank);
            if (a < 0 || b < 0) return (RankWeight / 2, null);
            return Math.Abs(a - b) switch
            {
                0 => (RankWeight, $"cùng rank {theirs.Rank}"),
                1 => (RankWeight, "rank gần nhau"),
                2 => (RankWeight / 2, null),
                _ => (0, null),
            };
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
                    TeamRole = u.Profile.TeamRole,
                    TalkLevel = u.Profile.TalkLevel,
                    BanterLevel = u.Profile.BanterLevel,
                    Games = u.GameProfiles.Select(g => new PlayerGame
                    {
                        GameId = g.GameId,
                        GameName = g.Game.GameName,
                        Position = g.PreferredPosition,
                        Purpose = g.Purpose,
                        Rank = g.Rank,
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
            public string? TeamRole { get; set; }
            public string? TalkLevel { get; set; }
            public string? BanterLevel { get; set; }
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
            public string? Rank { get; set; }
        }
    }
}
