using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Quest Controller
    //   POST api/quest/claim-daily - Điểm danh hằng ngày (cần token)
    // ============================================================
    [Authorize]
    public class QuestController : ApiControllerBase
    {
        private readonly IQuestService _questService;

        public QuestController(IQuestService questService)
        {
            _questService = questService;
        }

        [HttpPost("claim-daily")]
        public async Task<IActionResult> ClaimDaily() =>
            ToActionResult(await _questService.ClaimDailyRewardAsync(User.GetUserId()));
    }
}
