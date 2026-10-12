using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Thông báo trong app (cần token). Thông báo mới đẩy qua SignalR: sự kiện "notification"
    //   GET  api/notifications?before=     - Danh sách (mới -> cũ, 30 cái/lần)
    //   GET  api/notifications/summary     - Số chưa đọc cho nút 🔔 và số cuộc trò chuyện có tin chưa đọc cho nút 💬
    //   POST api/notifications/read-all    - Đánh dấu tất cả đã đọc
    //   POST api/notifications/{id}/read   - Đánh dấu 1 thông báo đã đọc
    // ============================================================
    [Authorize]
    public class NotificationsController : ApiControllerBase
    {
        private readonly INotificationService _notifications;
        private readonly IBadgeService _badges;

        public NotificationsController(INotificationService notifications, IBadgeService badges)
        {
            _notifications = notifications;
            _badges = badges;
        }

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] DateTime? before) => Ok(await _notifications.GetAsync(User.GetUserId(), before));

        // Gọi khi mở app -> tiện kiểm tra luôn huy hiệu mới (trao thì có thêm thông báo trước khi đếm)
        [HttpGet("summary")]
        public async Task<IActionResult> Summary()
        {
            await _badges.EvaluateAsync(User.GetUserId());
            return Ok(await _notifications.GetSummaryAsync(User.GetUserId()));
        }

        [HttpPost("read-all")]
        public async Task<IActionResult> ReadAll()
        {
            await _notifications.MarkReadAsync(User.GetUserId(), null);
            return NoContent();
        }

        [HttpPost("{id:guid}/read")]
        public async Task<IActionResult> Read(Guid id)
        {
            await _notifications.MarkReadAsync(User.GetUserId(), id);
            return NoContent();
        }
    }
}
