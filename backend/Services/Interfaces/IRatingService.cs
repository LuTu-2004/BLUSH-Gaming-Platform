using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IRatingService
    {
        Task<MyRatingDto> GetMineAsync(Guid userId);

        /// Gửi lần đầu hoặc sửa đánh giá cũ (mỗi người 1 đánh giá)
        Task<ServiceResult<MyRatingDto>> SubmitAsync(Guid userId, SubmitRatingRequest request);

        /// Admin: lịch sử đánh giá mới nhất trước, lọc theo số sao / tên / email + số liệu tổng
        Task<AdminRatingListDto> GetForAdminAsync(int? stars, string? search, int page, int pageSize);
    }
}
