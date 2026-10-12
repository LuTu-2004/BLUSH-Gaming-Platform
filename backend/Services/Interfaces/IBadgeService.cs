using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IBadgeService
    {
        /// Kiểm tra luật của từng huy hiệu chưa có, đạt thì trao + báo 🔔. Gọi khi mở app / xem huy hiệu.
        Task EvaluateAsync(Guid userId);

        /// Mọi huy hiệu: đã nhận (kèm ngày) hoặc chưa (kèm điều kiện)
        Task<List<BadgeDto>> GetMineAsync(Guid userId);
    }
}
