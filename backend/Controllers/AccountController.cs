using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Tài khoản (cần token)
    //   POST api/account/delete - Tự xóa tài khoản { password } hoặc { googleIdToken }
    // ============================================================
    [Authorize]
    public class AccountController : ApiControllerBase
    {
        private readonly IAccountService _accountService;

        public AccountController(IAccountService accountService)
        {
            _accountService = accountService;
        }

        [HttpPost("delete")]
        public async Task<IActionResult> Delete([FromBody] DeleteAccountRequest request) =>
            ToActionResult(await _accountService.DeleteAsync(User.GetUserId(), request));
    }
}
