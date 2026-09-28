using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Auth Controller
    //   POST api/auth/register         - Đăng ký (gửi mã OTP về email, chưa đăng nhập)
    //   POST api/auth/verify-email     - Nhập mã OTP -> xác minh email + đăng nhập
    //   POST api/auth/resend-otp       - Gửi lại mã (VerifyEmail / ResetPassword)
    //   POST api/auth/login            - Đăng nhập bằng email + mật khẩu
    //   POST api/auth/google           - Đăng nhập bằng Google (gửi ID Token)
    //   POST api/auth/forgot-password  - Gửi mã đặt lại mật khẩu
    //   POST api/auth/reset-password   - Nhập mã + mật khẩu mới
    //   GET  api/auth/me               - Lấy thông tin người đang đăng nhập (cần token)
    // ============================================================
    public class AuthController : ApiControllerBase
    {
        private readonly IAuthService _authService;
        private readonly IUserService _userService;

        public AuthController(IAuthService authService, IUserService userService)
        {
            _authService = authService;
            _userService = userService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request) =>
            ToActionResult(await _authService.RegisterAsync(request));

        [HttpPost("verify-email")]
        public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailRequest request) =>
            ToActionResult(await _authService.VerifyEmailAsync(request));

        [HttpPost("resend-otp")]
        public async Task<IActionResult> ResendOtp([FromBody] ResendOtpRequest request) =>
            ToActionResult(await _authService.ResendOtpAsync(request));

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request) =>
            ToActionResult(await _authService.LoginAsync(request));

        [HttpPost("google")]
        public async Task<IActionResult> Google([FromBody] GoogleLoginRequest request) =>
            ToActionResult(await _authService.LoginWithGoogleAsync(request.IdToken));

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request) =>
            ToActionResult(await _authService.ForgotPasswordAsync(request));

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request) =>
            ToActionResult(await _authService.ResetPasswordAsync(request));

        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
            var user = await _userService.GetUserDtoAsync(User.GetUserId());
            return user == null ? Unauthorized() : Ok(user);
        }
    }
}
