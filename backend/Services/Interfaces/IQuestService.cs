using Blush.Api.DataAccess.Entities;

namespace Blush.Api.Services.Interfaces
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Interface định nghĩa các hàm nghiệp vụ Quest
    // Dành cho Backend Dev định nghĩa hợp đồng hàm nghiệp vụ
    // ============================================================
    public interface IQuestService
    {
        Task<QuestResultDto> ClaimDailyRewardAsync(string userId);
    }

    public class QuestResultDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int AddedCoins { get; set; }
        public int AddedExp { get; set; }
        public User? User { get; set; }
    }
}
