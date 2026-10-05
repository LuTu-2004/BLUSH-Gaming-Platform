using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Khảo sát sau đăng ký (cần token)
    //   GET  api/onboarding/options - Danh sách game, khung giờ, khu vực, sở thích
    //   GET  api/onboarding         - Câu trả lời đã lưu (để sửa lại trong Hồ sơ)
    //   POST api/onboarding         - Lưu câu trả lời, trả về UserDto (onboardingCompleted = true)
    // ============================================================
    [Authorize]
    public class OnboardingController : ApiControllerBase
    {
        private readonly IOnboardingService _onboardingService;

        public OnboardingController(IOnboardingService onboardingService)
        {
            _onboardingService = onboardingService;
        }

        [HttpGet("options")]
        public async Task<IActionResult> GetOptions() => Ok(await _onboardingService.GetOptionsAsync());

        [HttpGet]
        public async Task<IActionResult> GetAnswers() => Ok(await _onboardingService.GetAnswersAsync(User.GetUserId()));

        [HttpPost]
        public async Task<IActionResult> Save([FromBody] OnboardingRequest request) =>
            ToActionResult(await _onboardingService.SaveAsync(User.GetUserId(), request));
    }
}
