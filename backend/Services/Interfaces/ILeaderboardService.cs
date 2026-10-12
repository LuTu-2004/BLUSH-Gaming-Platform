using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface ILeaderboardService
    {
        /// [region] null = toàn quốc, [gameId] null = mọi game
        Task<ServiceResult<LeaderboardDto>> GetAsync(Guid userId, string? region, int? gameId, int limit);
    }
}
