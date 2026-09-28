using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Interface định nghĩa các hàm nghiệp vụ Quest
    // ============================================================
    public interface IQuestService
    {
        Task<ServiceResult<QuestResultDto>> ClaimDailyRewardAsync(Guid userId);
    }
}
