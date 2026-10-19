using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Người dùng đánh giá app BLUSH (1-5 sao + góp ý)
    // Mỗi người 1 đánh giá; gửi lại thì sửa đánh giá cũ (điểm trung bình không bị 1 người kéo lệch).
    // ============================================================
    public class RatingService : IRatingService
    {
        /// Dùng app bao nhiêu ngày thì app tự hỏi đánh giá
        public const int AskAfterDays = 3;

        private readonly BlushDbContext _context;

        public RatingService(BlushDbContext context)
        {
            _context = context;
        }

        public async Task<MyRatingDto> GetMineAsync(Guid userId)
        {
            var rating = await _context.AppRatings.AsNoTracking().FirstOrDefaultAsync(r => r.UserId == userId);
            if (rating != null) return ToDto(rating);

            var createdAt = await _context.Users.Where(u => u.Id == userId).Select(u => u.CreatedAt).FirstOrDefaultAsync();
            return new MyRatingDto { ShouldAsk = createdAt != default && createdAt <= DateTime.UtcNow.AddDays(-AskAfterDays) };
        }

        public async Task<ServiceResult<MyRatingDto>> SubmitAsync(Guid userId, SubmitRatingRequest request)
        {
            var comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim();
            var now = DateTime.UtcNow;

            var rating = await _context.AppRatings.FirstOrDefaultAsync(r => r.UserId == userId);
            if (rating == null)
            {
                rating = new AppRating { UserId = userId, CreatedAt = now };
                _context.AppRatings.Add(rating);
            }
            rating.Stars = (byte)request.Stars;
            rating.Comment = comment;
            rating.UpdatedAt = now;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // Bấm gửi 2 lần cùng lúc -> lần sau trùng UserId: sửa dòng đã có
                _context.ChangeTracker.Clear();
                await _context.AppRatings.Where(r => r.UserId == userId).ExecuteUpdateAsync(s => s
                    .SetProperty(r => r.Stars, (byte)request.Stars)
                    .SetProperty(r => r.Comment, comment)
                    .SetProperty(r => r.UpdatedAt, now));
                rating = await _context.AppRatings.AsNoTracking().FirstAsync(r => r.UserId == userId);
            }
            return ServiceResult<MyRatingDto>.Ok(ToDto(rating));
        }

        public async Task<AdminRatingListDto> GetForAdminAsync(int? stars, string? search, int page, int pageSize)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = from r in _context.AppRatings.AsNoTracking()
                        join u in _context.Users on r.UserId equals u.Id
                        select new { Rating = r, User = u };
            if (stars is >= 1 and <= 5) query = query.Where(x => x.Rating.Stars == stars);
            if (!string.IsNullOrWhiteSpace(search))
            {
                var keyword = search.Trim();
                query = query.Where(x => x.User.Email.Contains(keyword) || (x.User.Profile != null && x.User.Profile.DisplayName.Contains(keyword)));
            }

            var total = await query.CountAsync();
            var items = await query
                .OrderByDescending(x => x.Rating.UpdatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(x => new AdminRatingDto
                {
                    UserId = x.User.Id,
                    Email = x.User.Email,
                    DisplayName = x.User.Profile != null ? x.User.Profile.DisplayName : x.User.Email,
                    AvatarUrl = x.User.Profile != null ? x.User.Profile.AvatarUrl : null,
                    Stars = x.Rating.Stars,
                    Comment = x.Rating.Comment,
                    CreatedAt = x.Rating.CreatedAt,
                    UpdatedAt = x.Rating.UpdatedAt,
                })
                .ToListAsync();

            return new AdminRatingListDto { Items = items, Total = total, Page = page, PageSize = pageSize, Stats = await GetStatsAsync() };
        }

        private async Task<AdminRatingStatsDto> GetStatsAsync()
        {
            var counts = await _context.AppRatings.GroupBy(r => r.Stars).Select(g => new { Stars = g.Key, Count = g.Count() }).ToListAsync();
            var stats = new AdminRatingStatsDto();
            foreach (var c in counts) stats.ByStars[c.Stars - 1] = c.Count;
            stats.Count = stats.ByStars.Sum();
            if (stats.Count > 0) stats.Average = Math.Round(counts.Sum(c => c.Stars * c.Count) / (double)stats.Count, 1);
            return stats;
        }

        private static MyRatingDto ToDto(AppRating r) =>
            new() { Stars = r.Stars, Comment = r.Comment, UpdatedAt = r.UpdatedAt, ShouldAsk = false };
    }
}
