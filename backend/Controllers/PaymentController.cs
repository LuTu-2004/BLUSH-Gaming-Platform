using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Blush.Api.DataAccess;
using Blush.Api.Dtos;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Payment Controller
    //   POST api/payment/create-checkout (cần token)
    // TODO (bước 5): lưu Transaction trạng thái Pending và xác nhận qua webhook PayOS
    // ============================================================
    [Authorize]
    public class PaymentController : ApiControllerBase
    {
        // Tài khoản nhận tiền demo - phải trùng với thông tin hiển thị ở checkout_screen.dart
        private const string BankCode = "MB";
        private const string BankAccount = "0388888888";

        private readonly BlushDbContext _context;

        public PaymentController(BlushDbContext context)
        {
            _context = context;
        }

        [HttpPost("create-checkout")]
        public async Task<IActionResult> CreateCheckout([FromBody] CheckoutRequest request)
        {
            var userId = User.GetUserId();

            var package = await _context.VipPackages.FirstOrDefaultAsync(p => p.PackageCode == request.PlanId && p.IsActive);
            if (package == null)
            {
                return NotFound(new { message = $"Không tìm thấy gói '{request.PlanId}'!" });
            }

            long orderCode = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            long amount = (long)package.Price;
            string addInfo = Uri.EscapeDataString($"NAP BLUSH {package.PackageCode} {userId}");
            string qrImageUrl = $"https://img.vietqr.io/image/{BankCode}-{BankAccount}-qr_only.png?amount={amount}&addInfo={addInfo}";

            return Ok(new
            {
                orderCode,
                amount,
                packageName = package.PackageName,
                qrImageUrl
            });
        }
    }
}
