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

        private static MyRatingDto ToDto(AppRating r) =>
            new() { Stars = r.Stars, Comment = r.Comment, UpdatedAt = r.UpdatedAt, ShouldAsk = false };
    }
}
