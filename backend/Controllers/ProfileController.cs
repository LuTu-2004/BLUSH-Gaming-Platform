using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Hồ sơ hiển thị (cần token)
    //   POST   api/profile        - Lưu giới thiệu + 2 câu hỏi cá nhân, trả về UserDto mới
    //   POST   api/profile/avatar - Đổi ảnh đại diện (multipart/form-data, trường "file": JPG/PNG/WebP, tối đa 5MB)
    //   DELETE api/profile/avatar - Gỡ ảnh đại diện
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

        [HttpPost("avatar")]
        [RequestSizeLimit(6 * 1024 * 1024)] // chặn sớm ở tầng nhận request, giới hạn chính xác nằm trong UserService
        public async Task<IActionResult> UploadAvatar(IFormFile? file, CancellationToken ct)
        {
            if (file == null) return BadRequest(new { message = "Chưa chọn ảnh." });
            await using var stream = file.OpenReadStream();
            return ToActionResult(await _userService.UpdateAvatarAsync(User.GetUserId(), stream, file.Length, ct));
        }

        [HttpDelete("avatar")]
        public async Task<IActionResult> RemoveAvatar() => ToActionResult(await _userService.RemoveAvatarAsync(User.GetUserId()));
    }
}
