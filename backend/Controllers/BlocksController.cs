using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Chặn người dùng (cần token)
    //   GET    api/blocks           - Người mình đã chặn
    //   POST   api/blocks/{userId}  - Chặn (chặn rồi thì bỏ qua)
    //   DELETE api/blocks/{userId}  - Bỏ chặn
    // ============================================================
    [Authorize]
    public class BlocksController : ApiControllerBase
    {
        private readonly IBlockService _blockService;

        public BlocksController(IBlockService blockService)
        {
            _blockService = blockService;
        }

        [HttpGet]
        public async Task<IActionResult> GetBlocked() => Ok(await _blockService.GetBlockedAsync(User.GetUserId()));

        [HttpPost("{userId:guid}")]
        public async Task<IActionResult> Block(Guid userId) => ToActionResult(await _blockService.BlockAsync(User.GetUserId(), userId));

        [HttpDelete("{userId:guid}")]
        public async Task<IActionResult> Unblock(Guid userId) => ToActionResult(await _blockService.UnblockAsync(User.GetUserId(), userId));
    }
}
