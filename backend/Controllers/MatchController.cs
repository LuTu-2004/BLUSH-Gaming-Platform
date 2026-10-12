using Blush.Api.DataAccess.Entities;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Gợi ý đồng đội (cần token)
    //   GET api/match/suggestions?gameId=1&limit=20
    //   Lỗi 400 + code ONBOARDING_REQUIRED nếu chưa làm khảo sát
    //   Xem gợi ý thành công -> cộng tiến độ nhiệm vụ "Ghép đội 1 lần"
    // ============================================================
    [Authorize]
    public class MatchController : ApiControllerBase
    {
        private readonly IMatchingService _matchingService;
        private readonly IQuestService _questService;

        public MatchController(IMatchingService matchingService, IQuestService questService)
        {
            _matchingService = matchingService;
            _questService = questService;
        }

        [HttpGet("suggestions")]
        public async Task<IActionResult> GetSuggestions([FromQuery] int? gameId, [FromQuery] int limit = 20)
        {
            var userId = User.GetUserId();
            var result = await _matchingService.GetSuggestionsAsync(userId, gameId, limit);
            if (result.Success) await _questService.RecordProgressAsync(userId, QuestCode.DailyMatch);
            return ToActionResult(result);
        }
    }
}
