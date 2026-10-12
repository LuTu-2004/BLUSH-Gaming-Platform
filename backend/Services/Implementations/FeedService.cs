using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Zone + Feed
    //   Xem bài: Zone thường ai cũng xem được; Zone kín cần BLUSH Pass Pro (Staff/Admin xem được hết)
    //   Đăng bài: phải là thành viên Zone. Gỡ bài / bình luận: người đăng hoặc Staff/Admin
    //   Đã chặn nhau thì không thấy bài / bình luận của nhau, không thả tim / bình luận bài của nhau
    //   Nhiệm vụ: đăng bài, thả tim, bình luận (thả tim / bình luận bài của chính mình không tính)
    // ============================================================
    public class FeedService : IFeedService
    {
        public const int PageSize = 20;
        private const int MaxComments = 200;

        private readonly BlushDbContext _context;
        private readonly IQuestService _questService;
        private readonly INotificationService _notifications;

        public FeedService(BlushDbContext context, IQuestService questService, INotificationService notifications)
        {
            _context = context;
            _questService = questService;
            _notifications = notifications;
        }

        // ─────────────────────────── ZONE ───────────────────────────

        public async Task<List<ZoneDto>> GetZonesAsync(Guid userId, bool isModerator)
        {
            var tier = await VipTier.GetAsync(_context, userId);
            var zones = await _context.Zones.AsNoTracking().Include(z => z.Game).OrderBy(z => z.GameId).ThenBy(z => z.Id).ToListAsync();
            var memberCounts = await _context.UserZones.GroupBy(m => m.ZoneId).Select(g => new { g.Key, Count = g.Count() }).ToDictionaryAsync(x => x.Key, x => x.Count);
            var mine = (await _context.UserZones.Where(m => m.UserId == userId).Select(m => m.ZoneId).ToListAsync()).ToHashSet();
            return zones.Select(z => ToDto(z, memberCounts.GetValueOrDefault(z.Id), mine.Contains(z.Id), CanAccess(z, tier, isModerator))).ToList();
        }

        public async Task<ServiceResult<ZoneDto>> JoinAsync(Guid userId, int zoneId, bool isModerator)
        {
            var zone = await _context.Zones.AsNoTracking().Include(z => z.Game).FirstOrDefaultAsync(z => z.Id == zoneId);
            if (zone == null) return ServiceResult<ZoneDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy Zone!");
            if (!CanAccess(zone, await VipTier.GetAsync(_context, userId), isModerator))
            {
                return ServiceResult<ZoneDto>.Fail(StatusCodes.Status403Forbidden, "Zone kín dành cho thành viên BLUSH Pass Pro.");
            }

            if (!await _context.UserZones.AnyAsync(m => m.UserId == userId && m.ZoneId == zoneId))
            {
                _context.UserZones.Add(new UserZone { UserId = userId, ZoneId = zoneId, JoinedAt = DateTime.UtcNow });
                try { await _context.SaveChangesAsync(); }
                catch (DbUpdateException) { /* bấm 2 lần cùng lúc: đã là thành viên */ }
            }
            return ServiceResult<ZoneDto>.Ok(await ZoneDtoAsync(zone, userId, true, true));
        }

        public async Task<ServiceResult<ZoneDto>> LeaveAsync(Guid userId, int zoneId, bool isModerator)
        {
            var zone = await _context.Zones.AsNoTracking().Include(z => z.Game).FirstOrDefaultAsync(z => z.Id == zoneId);
            if (zone == null) return ServiceResult<ZoneDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy Zone!");
            await _context.UserZones.Where(m => m.UserId == userId && m.ZoneId == zoneId).ExecuteDeleteAsync();
            return ServiceResult<ZoneDto>.Ok(await ZoneDtoAsync(zone, userId, false, CanAccess(zone, await VipTier.GetAsync(_context, userId), isModerator)));
        }

        public async Task AssignZonesFromOnboardingAsync(Guid userId)
        {
            var zoneIds = await (from g in _context.UserGameProfiles
                                 join z in _context.Zones on new { g.GameId, Purpose = g.Purpose! } equals new { z.GameId, z.Purpose }
                                 where g.UserId == userId && !z.IsVipOnly
                                 select z.Id).Distinct().ToListAsync();
            var already = await _context.UserZones.Where(m => m.UserId == userId).Select(m => m.ZoneId).ToListAsync();
            var now = DateTime.UtcNow;
            _context.UserZones.AddRange(zoneIds.Except(already).Select(id => new UserZone { UserId = userId, ZoneId = id, JoinedAt = now }));
            await _context.SaveChangesAsync();
        }

        // ─────────────────────────── BÀI ĐĂNG ───────────────────────────

        public async Task<ServiceResult<List<PostDto>>> GetPostsAsync(Guid userId, int? zoneId, DateTime? before, bool isModerator)
        {
            var tier = await VipTier.GetAsync(_context, userId);
            IQueryable<Post> posts;
            if (zoneId != null)
            {
                var zone = await _context.Zones.AsNoTracking().FirstOrDefaultAsync(z => z.Id == zoneId);
                if (zone == null) return ServiceResult<List<PostDto>>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy Zone!");
                if (!CanAccess(zone, tier, isModerator))
                {
                    return ServiceResult<List<PostDto>>.Fail(StatusCodes.Status403Forbidden, "Zone kín dành cho thành viên BLUSH Pass Pro.");
                }
                posts = _context.Posts.Where(p => p.ZoneId == zoneId);
            }
            else
            {
                // Bảng tin: các Zone mình tham gia (Zone kín chỉ khi còn gói Pro)
                var canSeeVip = tier == VipTier.Pro || isModerator;
                posts = _context.Posts.Where(p => _context.UserZones.Any(m => m.UserId == userId && m.ZoneId == p.ZoneId)
                    && (canSeeVip || !_context.Zones.Any(z => z.Id == p.ZoneId && z.IsVipOnly)));
            }

            posts = VisibleTo(posts.Where(p => p.RemovedAt == null), userId);
            if (before != null) posts = posts.Where(p => p.CreatedAt < before);
            var page = posts.OrderByDescending(p => p.CreatedAt).Take(PageSize);
            return ServiceResult<List<PostDto>>.Ok(await ToDto(page, userId, isModerator).OrderByDescending(p => p.CreatedAt).ToListAsync());
        }

        public async Task<ServiceResult<PostDto>> CreatePostAsync(Guid userId, int zoneId, string content, bool isModerator)
        {
            var zone = await _context.Zones.AsNoTracking().FirstOrDefaultAsync(z => z.Id == zoneId);
            if (zone == null) return ServiceResult<PostDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy Zone!");
            if (!CanAccess(zone, await VipTier.GetAsync(_context, userId), isModerator))
            {
                return ServiceResult<PostDto>.Fail(StatusCodes.Status403Forbidden, "Zone kín dành cho thành viên BLUSH Pass Pro.");
            }
            if (!isModerator && !await _context.UserZones.AnyAsync(m => m.UserId == userId && m.ZoneId == zoneId))
            {
                return ServiceResult<PostDto>.Fail(StatusCodes.Status403Forbidden, "Tham gia Zone để đăng bài.");
            }
            content = content.Trim();
            if (content.Length == 0) return ServiceResult<PostDto>.Fail(StatusCodes.Status400BadRequest, "Bài viết trống.");

            var post = new Post { Id = Guid.NewGuid(), ZoneId = zoneId, AuthorId = userId, Content = content, CreatedAt = DateTime.UtcNow };
            _context.Posts.Add(post);
            await _context.SaveChangesAsync();
            await _questService.RecordProgressAsync(userId, QuestCode.DailyFeedPost);

            return ServiceResult<PostDto>.Ok(await ToDto(_context.Posts.Where(p => p.Id == post.Id), userId, isModerator).FirstAsync());
        }

        public async Task<ServiceResult<MessageResponse>> DeletePostAsync(Guid userId, Guid postId, bool isModerator)
        {
            var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == postId && p.RemovedAt == null);
            if (post == null) return ServiceResult<MessageResponse>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy bài viết!");
            if (post.AuthorId != userId && !isModerator)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status403Forbidden, "Bạn chỉ gỡ được bài của mình.");
            }
            post.RemovedAt = DateTime.UtcNow;
            post.RemovedBy = userId;
            await _context.SaveChangesAsync();
            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Đã gỡ bài viết." });
        }

        public async Task<ServiceResult<LikeResultDto>> SetLikeAsync(Guid userId, Guid postId, bool like, bool isModerator)
        {
            var (post, error) = await FindViewablePostAsync(userId, postId, isModerator);
            if (post == null) return ServiceResult<LikeResultDto>.Fail(error!.StatusCode, error.Error!);

            var exists = await _context.PostLikes.AnyAsync(l => l.PostId == postId && l.UserId == userId);
            if (like && !exists)
            {
                _context.PostLikes.Add(new PostLike { PostId = postId, UserId = userId, CreatedAt = DateTime.UtcNow });
                var added = true;
                try { await _context.SaveChangesAsync(); }
                catch (DbUpdateException) { added = false; } // bấm 2 lần cùng lúc
                if (added && post.AuthorId != userId)
                {
                    await _questService.RecordProgressAsync(userId, QuestCode.DailyFeedLike);
                    await _questService.RecordProgressAsync(userId, QuestCode.SeasonFeedInteract);
                    await _notifications.NotifyAsync(post.AuthorId, NotificationType.PostLiked,
                        $"{await DisplayNameAsync(userId)} đã thả tim bài viết của bạn", Excerpt(post.Content), $"zone:{post.ZoneId}");
                }
            }
            else if (!like && exists)
            {
                await _context.PostLikes.Where(l => l.PostId == postId && l.UserId == userId).ExecuteDeleteAsync();
            }

            return ServiceResult<LikeResultDto>.Ok(new LikeResultDto
            {
                Liked = like,
                LikeCount = await _context.PostLikes.CountAsync(l => l.PostId == postId),
            });
        }

        // ─────────────────────────── BÌNH LUẬN ───────────────────────────

        public async Task<ServiceResult<List<CommentDto>>> GetCommentsAsync(Guid userId, Guid postId, bool isModerator)
        {
            var (post, error) = await FindViewablePostAsync(userId, postId, isModerator);
            if (post == null) return ServiceResult<List<CommentDto>>.Fail(error!.StatusCode, error.Error!);

            var comments = VisibleTo(_context.PostComments.Where(c => c.PostId == postId && c.RemovedAt == null), userId)
                .OrderBy(c => c.CreatedAt).Take(MaxComments);
            return ServiceResult<List<CommentDto>>.Ok(await ToDto(comments, userId, isModerator).OrderBy(c => c.CreatedAt).ToListAsync());
        }

        public async Task<ServiceResult<CommentDto>> AddCommentAsync(Guid userId, Guid postId, string content, bool isModerator)
        {
            var (post, error) = await FindViewablePostAsync(userId, postId, isModerator);
            if (post == null) return ServiceResult<CommentDto>.Fail(error!.StatusCode, error.Error!);
            content = content.Trim();
            if (content.Length == 0) return ServiceResult<CommentDto>.Fail(StatusCodes.Status400BadRequest, "Bình luận trống.");

            var comment = new PostComment { Id = Guid.NewGuid(), PostId = postId, AuthorId = userId, Content = content, CreatedAt = DateTime.UtcNow };
            _context.PostComments.Add(comment);
            await _context.SaveChangesAsync();
            if (post.AuthorId != userId)
            {
                await _questService.RecordProgressAsync(userId, QuestCode.SeasonFeedInteract);
                await _notifications.NotifyAsync(post.AuthorId, NotificationType.PostCommented,
                    $"{await DisplayNameAsync(userId)} đã bình luận bài viết của bạn", Excerpt(content), $"zone:{post.ZoneId}");
            }

            return ServiceResult<CommentDto>.Ok(await ToDto(_context.PostComments.Where(c => c.Id == comment.Id), userId, isModerator).FirstAsync());
        }

        public async Task<ServiceResult<MessageResponse>> DeleteCommentAsync(Guid userId, Guid commentId, bool isModerator)
        {
            var comment = await _context.PostComments.FirstOrDefaultAsync(c => c.Id == commentId && c.RemovedAt == null);
            if (comment == null) return ServiceResult<MessageResponse>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy bình luận!");
            if (comment.AuthorId != userId && !isModerator)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status403Forbidden, "Bạn chỉ xóa được bình luận của mình.");
            }
            comment.RemovedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Đã xóa bình luận." });
        }

        // ─────────────────────────── HÀM DÙNG CHUNG ───────────────────────────

        private async Task<string> DisplayNameAsync(Guid userId) =>
            await _context.UserProfiles.Where(p => p.UserId == userId).Select(p => p.DisplayName).FirstOrDefaultAsync() ?? "Ai đó";

        private static string Excerpt(string text) => text.Length <= 80 ? text : text[..79].TrimEnd() + "…";

        private static bool CanAccess(Zone zone, string tier, bool isModerator) => !zone.IsVipOnly || tier == VipTier.Pro || isModerator;

        // Bài còn hiện, Zone xem được, không chặn nhau với người đăng
        private async Task<(Post? Post, ServiceResult<bool>? Error)> FindViewablePostAsync(Guid userId, Guid postId, bool isModerator)
        {
            var post = await VisibleTo(_context.Posts.Where(p => p.Id == postId && p.RemovedAt == null), userId).FirstOrDefaultAsync();
            if (post == null) return (null, ServiceResult<bool>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy bài viết!"));
            var zone = await _context.Zones.AsNoTracking().FirstAsync(z => z.Id == post.ZoneId);
            if (!CanAccess(zone, await VipTier.GetAsync(_context, userId), isModerator))
            {
                return (null, ServiceResult<bool>.Fail(StatusCodes.Status403Forbidden, "Zone kín dành cho thành viên BLUSH Pass Pro."));
            }
            return (post, null);
        }

        private IQueryable<Post> VisibleTo(IQueryable<Post> posts, Guid viewerId) =>
            posts.Where(p => !_context.UserBlocks.Any(b =>
                (b.BlockerId == viewerId && b.BlockedId == p.AuthorId) || (b.BlockerId == p.AuthorId && b.BlockedId == viewerId)));

        private IQueryable<PostComment> VisibleTo(IQueryable<PostComment> comments, Guid viewerId) =>
            comments.Where(c => !_context.UserBlocks.Any(b =>
                (b.BlockerId == viewerId && b.BlockedId == c.AuthorId) || (b.BlockerId == c.AuthorId && b.BlockedId == viewerId)));

        private IQueryable<PostDto> ToDto(IQueryable<Post> posts, Guid viewerId, bool isModerator)
        {
            var now = DateTime.UtcNow;
            return from p in posts
                   join u in _context.Users on p.AuthorId equals u.Id
                   join z in _context.Zones on p.ZoneId equals z.Id
                   select new PostDto
                   {
                       Id = p.Id,
                       ZoneId = p.ZoneId,
                       ZoneName = z.ZoneName,
                       Author = new FeedAuthorDto
                       {
                           Id = u.Id,
                           DisplayName = u.Profile != null ? u.Profile.DisplayName : "Người chơi",
                           AvatarEmoji = u.Profile != null ? u.Profile.AvatarEmoji : "🎮",
                           AvatarUrl = u.Profile != null ? u.Profile.AvatarUrl : null,
                           IsVip = u.Subscriptions.Any(s => s.StartAt <= now && s.EndAt > now),
                       },
                       Content = p.Content,
                       CreatedAt = p.CreatedAt,
                       LikeCount = _context.PostLikes.Count(l => l.PostId == p.Id),
                       CommentCount = _context.PostComments.Count(c => c.PostId == p.Id && c.RemovedAt == null),
                       LikedByMe = _context.PostLikes.Any(l => l.PostId == p.Id && l.UserId == viewerId),
                       CanDelete = isModerator || p.AuthorId == viewerId,
                   };
        }

        private IQueryable<CommentDto> ToDto(IQueryable<PostComment> comments, Guid viewerId, bool isModerator)
        {
            var now = DateTime.UtcNow;
            return from c in comments
                   join u in _context.Users on c.AuthorId equals u.Id
                   select new CommentDto
                   {
                       Id = c.Id,
                       PostId = c.PostId,
                       Author = new FeedAuthorDto
                       {
                           Id = u.Id,
                           DisplayName = u.Profile != null ? u.Profile.DisplayName : "Người chơi",
                           AvatarEmoji = u.Profile != null ? u.Profile.AvatarEmoji : "🎮",
                           AvatarUrl = u.Profile != null ? u.Profile.AvatarUrl : null,
                           IsVip = u.Subscriptions.Any(s => s.StartAt <= now && s.EndAt > now),
                       },
                       Content = c.Content,
                       CreatedAt = c.CreatedAt,
                       CanDelete = isModerator || c.AuthorId == viewerId,
                   };
        }

        private async Task<ZoneDto> ZoneDtoAsync(Zone zone, Guid userId, bool isMember, bool canAccess) =>
            ToDto(zone, await _context.UserZones.CountAsync(m => m.ZoneId == zone.Id), isMember, canAccess);

        private static ZoneDto ToDto(Zone z, int memberCount, bool isMember, bool canAccess) => new()
        {
            Id = z.Id,
            Name = z.ZoneName,
            GameId = z.GameId,
            GameName = z.Game.GameName,
            Purpose = z.Purpose,
            PurposeLabel = GameCatalog.PurposeLabel(z.Purpose),
            Description = z.Description,
            IsVipOnly = z.IsVipOnly,
            MemberCount = memberCount,
            IsMember = isMember,
            CanAccess = canAccess,
        };
    }
}
