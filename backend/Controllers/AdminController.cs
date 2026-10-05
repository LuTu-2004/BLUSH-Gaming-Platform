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
    // ============================================================
    [Authorize(Roles = "Admin")]
    public class AdminController : ApiControllerBase
    {
        private readonly IAdminPaymentService _adminPaymentService;

        public AdminController(IAdminPaymentService adminPaymentService)
        {
            _adminPaymentService = adminPaymentService;
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
    }
}
