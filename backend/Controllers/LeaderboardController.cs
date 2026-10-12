using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Bảng xếp hạng (cần token)
    //   GET api/leaderboard?region=HCM&gameId=2&limit=50 - Top EXP + hạng của mình
    // ============================================================
    [Authorize]
    public class LeaderboardController : ApiControllerBase
    {
        private readonly ILeaderboardService _leaderboardService;

        public LeaderboardController(ILeaderboardService leaderboardService)
        {
            _leaderboardService = leaderboardService;
        }

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] string? region, [FromQuery] int? gameId, [FromQuery] int limit = 50) =>
            ToActionResult(await _leaderboardService.GetAsync(User.GetUserId(), region, gameId, limit));
    }
}
