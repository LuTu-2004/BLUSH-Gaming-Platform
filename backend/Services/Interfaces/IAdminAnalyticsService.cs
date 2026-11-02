using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IAdminAnalyticsService
    {
        /// Số liệu Google Analytics [days] ngày gần nhất (landing page + app Android).
        /// Không bao giờ ném lỗi cấu hình: chưa sẵn sàng thì Available = false kèm lời nhắn cách sửa.
        Task<AdminAnalyticsDto> GetAsync(int days, CancellationToken ct = default);
    }
}
