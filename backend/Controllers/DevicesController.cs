using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Điện thoại nhận thông báo đẩy (cần token)
    //   POST api/devices             - Lưu mã FCM của máy này {token, platform}
    //   POST api/devices/unregister  - Gỡ mã khi đăng xuất {token}
    // ============================================================
    [Authorize]
    public class DevicesController : ApiControllerBase
    {
        private readonly IPushService _push;

        public DevicesController(IPushService push)
        {
            _push = push;
        }

        [HttpPost]
        public async Task<IActionResult> Register([FromBody] RegisterDeviceRequest request)
        {
            await _push.RegisterAsync(User.GetUserId(), request.Token.Trim(), request.Platform);
            return NoContent();
        }

        [HttpPost("unregister")]
        public async Task<IActionResult> Unregister([FromBody] UnregisterDeviceRequest request)
        {
            await _push.UnregisterAsync(User.GetUserId(), request.Token.Trim());
            return NoContent();
        }
    }
}
