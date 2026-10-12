using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // Nhật ký trận đấu + rank tự khai. App không đọc được kết quả từ game thật nên người chơi tự ghi,
    // đồng đội xác nhận mới được tính nhiệm vụ (chơi 3 trận, chuỗi thắng, hỗ trợ tân thủ) và huy hiệu Chúa Tryhard.
    public interface IMatchLogService
    {
        Task<MatchOptionsDto> GetOptionsAsync(Guid userId);

        /// Trận chờ mình xác nhận lên trước, rồi lịch sử gần nhất
        Task<List<MatchLogDto>> GetMineAsync(Guid userId);

        Task<ServiceResult<MatchLogDto>> CreateAsync(Guid userId, CreateMatchRequest request);
        Task<ServiceResult<MatchLogDto>> ConfirmAsync(Guid userId, Guid matchId, bool confirm);
        Task<ServiceResult<GameRankDto>> SetRankAsync(Guid userId, int gameId, string? rank);
    }
}
