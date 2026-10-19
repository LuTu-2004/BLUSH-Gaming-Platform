using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Đánh giá app BLUSH (cần token)
    //   GET  api/ratings/me - Đánh giá của mình + có nên hỏi đánh giá không
    //   POST api/ratings/me - Gửi / sửa đánh giá 1-5 sao + góp ý
    // ============================================================
    [Authorize]
    public class RatingsController : ApiControllerBase
    {
        private readonly IRatingService _ratingService;

        public RatingsController(IRatingService ratingService)
        {
            _ratingService = ratingService;
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetMine() => Ok(await _ratingService.GetMineAsync(User.GetUserId()));

        [HttpPost("me")]
        public async Task<IActionResult> Submit([FromBody] SubmitRatingRequest request) =>
            ToActionResult(await _ratingService.SubmitAsync(User.GetUserId(), request));
    }
}
