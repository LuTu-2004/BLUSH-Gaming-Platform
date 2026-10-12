using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Interface định nghĩa các hàm nghiệp vụ Quest
    // ============================================================
    public interface IQuestService
    {
        Task<ServiceResult<QuestResultDto>> ClaimDailyRewardAsync(Guid userId);

        // Danh sách nhiệm vụ đang mở + tiến độ kỳ hiện tại
        Task<List<QuestDto>> GetQuestsAsync(Guid userId);

        // Nhận quà nhiệm vụ đã hoàn thành (mỗi kỳ 1 lần)
        Task<ServiceResult<QuestResultDto>> ClaimQuestAsync(Guid userId, int questId);

        // Gọi từ tính năng tương ứng khi người dùng làm 1 hành động (VD: xem gợi ý đồng đội)
        Task RecordProgressAsync(Guid userId, string questCode, int amount = 1);

        // Tiến độ ít nhất bằng [value] (VD chuỗi thắng hiện tại, đã khai rank): chỉ tăng, không giảm
        Task SetProgressAtLeastAsync(Guid userId, string questCode, int value);
    }
}
