using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Tính năng AI (cần token)
    //   GET  api/ai/usage                  - Hạn mức AI còn lại (lượt hôm nay, tokens tháng này)
    //   POST api/ai/chat/{roomId}/suggest  - 3 câu gợi ý trong phòng chat (mở đầu / nối chuyện)
    //   POST api/ai/match/{userId}/explain - Vì sao mình hợp với người được gợi ý
    //   POST api/ai/logs/{id}/report       - Báo cáo câu trả lời AI không phù hợp { reason }
    // Hết lượt: 429 + code AI_QUOTA_EXCEEDED. Chưa cấu hình / Gemini lỗi: 503 + code AI_UNAVAILABLE (không trừ lượt).
    // ============================================================
    [Authorize]
    public class AiController : ApiControllerBase
    {
        private readonly IAiService _aiService;

        public AiController(IAiService aiService)
        {
            _aiService = aiService;
        }

        [HttpGet("usage")]
        public async Task<IActionResult> GetUsage() => Ok(await _aiService.GetUsageAsync(User.GetUserId()));

        [HttpPost("chat/{roomId:guid}/suggest")]
        public async Task<IActionResult> Suggest(Guid roomId) =>
            ToActionResult(await _aiService.SuggestMessagesAsync(User.GetUserId(), roomId));

        [HttpPost("match/{userId:guid}/explain")]
        public async Task<IActionResult> Explain(Guid userId) =>
            ToActionResult(await _aiService.ExplainMatchAsync(User.GetUserId(), userId));

        [HttpPost("logs/{id:guid}/report")]
        public async Task<IActionResult> Report(Guid id, [FromBody] ReportAiRequest request) =>
            ToActionResult(await _aiService.ReportAsync(User.GetUserId(), id, request.Reason));
    }
}
