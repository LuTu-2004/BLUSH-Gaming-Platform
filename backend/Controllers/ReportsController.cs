using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Người chơi báo cáo vi phạm (cần token)
    //   GET  api/reports/reasons - Danh sách lý do (mỗi lý do ứng với 1 mức độ nghiêm trọng)
    //   POST api/reports         - Gửi báo cáo { reportedUserId, reasonCode, detail }
    // ============================================================
    [Authorize]
    public class ReportsController : ApiControllerBase
    {
        private readonly IModerationService _moderationService;

        public ReportsController(IModerationService moderationService)
        {
            _moderationService = moderationService;
        }

        [HttpGet("reasons")]
        public IActionResult GetReasons() => Ok(_moderationService.GetReportReasons());

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateReportRequest request) =>
            ToActionResult(await _moderationService.CreateReportAsync(User.GetUserId(), request));
    }
}
