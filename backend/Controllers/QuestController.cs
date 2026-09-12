using Microsoft.AspNetCore.Mvc;
using Blush.Api.Services.Interfaces;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Web API Controller
    // Dành cho Backend Dev tạo đường dẫn API cho Frontend React gọi
    // API Route: POST api/quest/claim-daily
    // ============================================================
    [ApiController]
    [Route("api/[controller]")]
    public class QuestController : ControllerBase
    {
        private readonly IQuestService _questService;

        public QuestController(IQuestService questService)
        {
            _questService = questService;
        }

        [HttpPost("claim-daily")]
        public async Task<IActionResult> ClaimDaily([FromBody] ClaimQuestRequest request)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                return BadRequest(new { success = false, message = "UserId không được để trống!" });
            }

            var result = await _questService.ClaimDailyRewardAsync(request.UserId);

            if (!result.Success)
            {
                return NotFound(result);
            }

            return Ok(result);
        }
    }

    public class ClaimQuestRequest
    {
        public string UserId { get; set; } = string.Empty;
    }
}
