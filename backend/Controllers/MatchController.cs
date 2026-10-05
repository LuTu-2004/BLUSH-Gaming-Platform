using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Gợi ý đồng đội (cần token)
    //   GET api/match/suggestions?gameId=1&limit=20
    //   Lỗi 400 + code ONBOARDING_REQUIRED nếu chưa làm khảo sát
    // ============================================================
    [Authorize]
    public class MatchController : ApiControllerBase
    {
        private readonly IMatchingService _matchingService;

        public MatchController(IMatchingService matchingService)
        {
            _matchingService = matchingService;
        }

        [HttpGet("suggestions")]
        public async Task<IActionResult> GetSuggestions([FromQuery] int? gameId, [FromQuery] int limit = 20) =>
            ToActionResult(await _matchingService.GetSuggestionsAsync(User.GetUserId(), gameId, limit));
    }
}
