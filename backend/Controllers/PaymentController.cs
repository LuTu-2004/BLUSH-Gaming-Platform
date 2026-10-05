using System.Net;
using System.Text.Json;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Blush.Api.Services.Payments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Mua gói VIP
    //
    // App gọi (cần token):
    //   GET  api/payment/packages                           - Danh sách gói
    //   GET  api/payment/methods                            - Phương thức thanh toán (MoMo, VietQR)
    //   POST api/payment/checkout                           - Tạo giao dịch -> link thanh toán / QR
    //   GET  api/payment/transactions                       - Lịch sử thanh toán của mình
    //   GET  api/payment/transactions/{orderCode}           - Trạng thái 1 giao dịch (app hỏi lại vài giây 1 lần)
    //   POST api/payment/transactions/{orderCode}/cancel    - Hủy giao dịch đang chờ
    //   POST api/payment/mock/{orderCode}/complete          - Chế độ Mock: giả lập cổng báo kết quả
    //
    // Cổng thanh toán gọi (không có token, kiểm tra bằng chữ ký):
    //   POST api/payment/momo/ipn,     GET api/payment/momo/return
    //   POST api/payment/payos/webhook, GET api/payment/payos/return, GET api/payment/payos/cancel
    // ============================================================
    [Authorize]
    public class PaymentController : ApiControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpGet("packages")]
        public async Task<IActionResult> GetPackages() => Ok(await _paymentService.GetPackagesAsync());

        [HttpGet("methods")]
        public IActionResult GetMethods() => Ok(_paymentService.GetMethods());

        [HttpPost("checkout")]
        public async Task<IActionResult> Checkout([FromBody] CheckoutRequest request) =>
            ToActionResult(await _paymentService.CreateCheckoutAsync(
                User.GetUserId(), request, HttpContext.Connection.RemoteIpAddress?.ToString() ?? string.Empty));

        [HttpGet("transactions")]
        public async Task<IActionResult> GetMyTransactions() => Ok(await _paymentService.GetMyTransactionsAsync(User.GetUserId()));

        [HttpGet("transactions/{orderCode:long}")]
        public async Task<IActionResult> GetTransaction(long orderCode) =>
            ToActionResult(await _paymentService.GetTransactionAsync(User.GetUserId(), orderCode));

        [HttpPost("transactions/{orderCode:long}/cancel")]
        public async Task<IActionResult> Cancel(long orderCode) =>
            ToActionResult(await _paymentService.CancelAsync(User.GetUserId(), orderCode));

        [HttpPost("mock/{orderCode:long}/complete")]
        public async Task<IActionResult> CompleteMock(long orderCode, [FromBody] MockCompleteRequest request) =>
            ToActionResult(await _paymentService.CompleteMockAsync(User.GetUserId(), orderCode, request.Success));

        // ── MoMo ─────────────────────────────────────────────────────
        [AllowAnonymous]
        [HttpPost("momo/ipn")]
        public async Task<IActionResult> MomoIpn([FromServices] MomoGateway gateway, [FromBody] JsonElement body)
        {
            var data = body.EnumerateObject().ToDictionary(p => p.Name, p => (string?)(p.Value.ValueKind == JsonValueKind.String ? p.Value.GetString() : p.Value.GetRawText()));
            var result = gateway.Verify(data);
            if (result == null) return BadRequest();
            await _paymentService.ApplyGatewayResultAsync(result);
            return NoContent(); // MoMo yêu cầu trả 204
        }

        [AllowAnonymous]
        [HttpGet("momo/return")]
        public async Task<IActionResult> MomoReturn([FromServices] MomoGateway gateway) =>
            await ResultPage(gateway.Verify(Request.Query.ToDictionary(q => q.Key, q => (string?)q.Value.ToString())));

        // ── VietQR qua PayOS ─────────────────────────────────────────
        // PayOS gọi khi tiền tới tài khoản. Lúc khai báo URL webhook, PayOS cũng gửi thử 1 đơn mẫu (không có trong DB)
        // -> chữ ký đúng thì luôn trả 200 để PayOS chấp nhận URL.
        [AllowAnonymous]
        [HttpPost("payos/webhook")]
        public async Task<IActionResult> PayOsWebhook([FromServices] VietQrGateway gateway, [FromBody] JsonElement body)
        {
            var result = gateway.VerifyWebhook(body);
            if (result == null) return BadRequest(new { success = false, message = "Invalid signature" });
            await _paymentService.ApplyGatewayResultAsync(result);
            return Ok(new { success = true });
        }

        // Trình duyệt quay về từ trang PayOS. Tham số trên URL không có chữ ký -> không tin, tự hỏi lại PayOS.
        [AllowAnonymous]
        [HttpGet("payos/return")]
        [HttpGet("payos/cancel")]
        public async Task<IActionResult> PayOsReturn([FromQuery] long orderCode)
        {
            if (orderCode > 0) await _paymentService.ReconcileAsync(null, orderCode);
            return ResultHtml("Đã ghi nhận", "Bạn có thể quay lại app BLUSH, trạng thái giao dịch sẽ tự cập nhật.");
        }

        // Trình duyệt quay về sau khi trả tiền: cập nhật luôn (phòng khi IPN chưa tới được localhost) rồi báo quay lại app
        private async Task<IActionResult> ResultPage(GatewayResult? result)
        {
            if (result != null) await _paymentService.ApplyGatewayResultAsync(result);

            var (title, message) = result switch
            {
                null => ("Đang xác nhận giao dịch", "Chưa có kết quả cuối cùng. Bạn quay lại app BLUSH, trạng thái sẽ tự cập nhật."),
                { Success: true } => ("Thanh toán thành công 🎉", "BLUSH Pass đã được kích hoạt. Bạn có thể quay lại app BLUSH."),
                _ => ("Thanh toán chưa thành công", WebUtility.HtmlEncode(result.Message ?? "Giao dịch không thành công.") + " Bạn có thể quay lại app để thử lại."),
            };
            return ResultHtml(title, message);
        }

        private ContentResult ResultHtml(string title, string message)
        {
            var html = $"""
                <!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
                <title>BLUSH - {title}</title></head>
                <body style="margin:0;font-family:system-ui,sans-serif;background:#13131B;color:#E4E1ED;display:flex;min-height:100vh;align-items:center;justify-content:center;text-align:center">
                <div style="padding:24px;max-width:420px"><h1 style="font-size:22px">{title}</h1><p style="color:#CCC3D8;line-height:1.5">{message}</p>
                <p style="color:#7C3AED;font-weight:700">BLUSH Gaming</p></div></body></html>
                """;
            return Content(html, "text/html; charset=utf-8");
        }
    }
}
