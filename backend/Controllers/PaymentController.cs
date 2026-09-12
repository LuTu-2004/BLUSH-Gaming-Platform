using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Payment Controller
    // API Route: POST api/payment/create-checkout
    // ============================================================
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        [HttpPost("create-checkout")]
        public IActionResult CreateCheckout([FromBody] CheckoutRequest request)
        {
            long orderCode = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            string qrImageUrl = $"https://img.vietqr.io/image/MB-0388888888-qr_only.png?amount=19000&addInfo=NAP%20BLUSH%20VIP%20{request.UserId}";

            return Ok(new
            {
                success = true,
                orderCode = orderCode,
                amount = 19000,
                qrImageUrl = qrImageUrl
            });
        }
    }

    public class CheckoutRequest
    {
        public string UserId { get; set; } = string.Empty;
        public string PlanId { get; set; } = "vip_1m";
    }
}
