using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Hồ sơ hiển thị (cần token)
    //   POST api/profile - Lưu giới thiệu + 2 câu hỏi cá nhân, trả về UserDto mới
    // ============================================================
    [Authorize]
    public class ProfileController : ApiControllerBase
    {
        private readonly IUserService _userService;

        public ProfileController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost]
        public async Task<IActionResult> Update([FromBody] UpdateProfileRequest request) =>
            ToActionResult(await _userService.UpdateProfileAsync(User.GetUserId(), request));
    }
}
