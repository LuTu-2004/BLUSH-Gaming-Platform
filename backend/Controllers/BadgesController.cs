using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Huy hiệu (cần token)
    //   GET api/badges/me - Mọi huy hiệu: đã nhận (kèm ngày) / chưa (kèm điều kiện). Gọi là tự kiểm tra + trao huy hiệu mới
    // ============================================================
    [Authorize]
    public class BadgesController : ApiControllerBase
    {
        private readonly IBadgeService _badges;

        public BadgesController(IBadgeService badges)
        {
            _badges = badges;
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetMine() => Ok(await _badges.GetMineAsync(User.GetUserId()));
    }
}
