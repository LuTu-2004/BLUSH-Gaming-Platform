using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Khu quản trị (chỉ role Admin)
    //   GET  api/admin/payments/summary?days=30                    - Số liệu doanh thu cho Dashboard
    //   GET  api/admin/payments/transactions?status=&method=&search=&page=1&pageSize=20
    //   POST api/admin/payments/transactions/{orderCode}/confirm   - Xác nhận đã nhận chuyển khoản VietQR
    //   GET  api/admin/users?search=&role=&status=&page=1&pageSize=20 - Danh sách người dùng + số liệu KPI
    //   POST api/admin/users/{id}/status   - Khóa vĩnh viễn / tạm khóa N ngày / mở khóa
    //   POST api/admin/users/{id}/role     - Đổi vai trò User / Staff / Admin
    //   POST api/admin/ai/playstyles?max=50 - AI phân tích phong cách chơi cho hồ sơ cũ chưa phân tích
    // ============================================================
    [Authorize(Roles = "Admin")]
    public class AdminController : ApiControllerBase
    {
        private readonly IAdminPaymentService _adminPaymentService;
        private readonly IAdminUserService _adminUserService;
        private readonly IPlaystyleAnalyzer _playstyle;

        public AdminController(IAdminPaymentService adminPaymentService, IAdminUserService adminUserService, IPlaystyleAnalyzer playstyle)
        {
            _adminPaymentService = adminPaymentService;
            _adminUserService = adminUserService;
            _playstyle = playstyle;
        }

        [HttpGet("payments/summary")]
        public async Task<IActionResult> GetPaymentSummary([FromQuery] int days = 30) =>
            Ok(await _adminPaymentService.GetSummaryAsync(days));

        [HttpGet("payments/transactions")]
        public async Task<IActionResult> GetTransactions(
            [FromQuery] string? status, [FromQuery] string? method, [FromQuery] string? search,
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20) =>
            Ok(await _adminPaymentService.GetTransactionsAsync(status, method, search, page, pageSize));

        [HttpPost("payments/transactions/{orderCode:long}/confirm")]
        public async Task<IActionResult> ConfirmBankTransfer(long orderCode) =>
            ToActionResult(await _adminPaymentService.ConfirmBankTransferAsync(orderCode, User.GetUserId()));

        [HttpGet("users")]
        public async Task<IActionResult> GetUsers(
            [FromQuery] string? search, [FromQuery] string? role, [FromQuery] string? status,
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20) =>
            Ok(await _adminUserService.GetUsersAsync(search, role, status, page, pageSize));

        [HttpPost("users/{id:guid}/status")]
        public async Task<IActionResult> UpdateUserStatus(Guid id, [FromBody] UpdateUserStatusRequest request) =>
            ToActionResult(await _adminUserService.UpdateStatusAsync(User.GetUserId(), id, request));

        [HttpPost("users/{id:guid}/role")]
        public async Task<IActionResult> UpdateUserRole(Guid id, [FromBody] UpdateUserRoleRequest request) =>
            ToActionResult(await _adminUserService.UpdateRoleAsync(User.GetUserId(), id, request));

        [HttpPost("ai/playstyles")]
        public async Task<IActionResult> BackfillPlaystyles([FromQuery] int max = 50) =>
            Ok(new MessageResponse { Message = $"AI đã phân tích {await _playstyle.BackfillAsync(max)} hồ sơ." });
    }
}
