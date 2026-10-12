using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Quest Controller (cần token)
    //   POST api/quest/claim-daily  - Điểm danh hằng ngày
    //   GET  api/quest              - Nhiệm vụ ngày/tuần/mùa + tiến độ kỳ hiện tại
    //   POST api/quest/{id}/claim   - Nhận quà nhiệm vụ đã hoàn thành
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

        [HttpGet]
        public async Task<IActionResult> GetQuests() => Ok(await _questService.GetQuestsAsync(User.GetUserId()));

        [HttpPost("{id:int}/claim")]
        public async Task<IActionResult> Claim(int id) =>
            ToActionResult(await _questService.ClaimQuestAsync(User.GetUserId(), id));
    }
}
