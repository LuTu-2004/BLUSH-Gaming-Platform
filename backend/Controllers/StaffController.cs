using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Khu kiểm duyệt (role Staff hoặc Admin)
    //   GET    api/staff/reports?status=Pending&page=1&pageSize=20 - Báo cáo vi phạm + số liệu
    //   POST   api/staff/reports/{id}/resolve      - Xử lý: Warn / Suspend (tạm khóa 3 ngày) / Dismiss
    //   GET    api/staff/icebreakers               - Tất cả câu hỏi phá băng
    //   GET    api/staff/icebreakers/categories    - Loại câu hỏi
    //   POST   api/staff/icebreakers               - Thêm câu hỏi
    //   POST   api/staff/icebreakers/{id}/active   - Bật / tắt
    //   DELETE api/staff/icebreakers/{id}          - Xóa (câu đã dùng trong chat thì chỉ tắt được)
    // ============================================================
    [Authorize(Roles = "Staff,Admin")]
    public class StaffController : ApiControllerBase
    {
        private readonly IModerationService _moderationService;

        public StaffController(IModerationService moderationService)
        {
            _moderationService = moderationService;
        }

        [HttpGet("reports")]
        public async Task<IActionResult> GetReports([FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20) =>
            Ok(await _moderationService.GetReportsAsync(status, page, pageSize));

        [HttpPost("reports/{id:int}/resolve")]
        public async Task<IActionResult> ResolveReport(int id, [FromBody] ResolveReportRequest request) =>
            ToActionResult(await _moderationService.ResolveReportAsync(User.GetUserId(), id, request));

        [HttpGet("icebreakers")]
        public async Task<IActionResult> GetIceBreakers() => Ok(await _moderationService.GetIceBreakersAsync());

        [HttpGet("icebreakers/categories")]
        public IActionResult GetIceBreakerCategories() => Ok(_moderationService.GetIceBreakerCategories());

        [HttpPost("icebreakers")]
        public async Task<IActionResult> CreateIceBreaker([FromBody] CreateIceBreakerRequest request) =>
            ToActionResult(await _moderationService.CreateIceBreakerAsync(request));

        [HttpPost("icebreakers/{id:int}/active")]
        public async Task<IActionResult> SetIceBreakerActive(int id, [FromBody] SetActiveRequest request) =>
            ToActionResult(await _moderationService.SetIceBreakerActiveAsync(id, request.IsActive));

        [HttpDelete("icebreakers/{id:int}")]
        public async Task<IActionResult> DeleteIceBreaker(int id) =>
            ToActionResult(await _moderationService.DeleteIceBreakerAsync(id));
    }
}
