using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Nhật ký trận đấu + rank (cần token)
    //   GET  api/matches               - Trận chờ mình xác nhận + lịch sử
    //   GET  api/matches/options       - Đồng đội có thể chọn (người đã chat) + game của mình kèm danh sách rank
    //   POST api/matches               - Ghi trận { teammateId, gameId, result: Win|Loss } -> đồng đội nhận thông báo
    //   POST api/matches/{id}/confirm  - Đồng đội xác nhận { confirm: true|false }
    //   POST api/matches/rank          - Khai rank { gameId, rank } (null = bỏ)
    // ============================================================
    [Authorize]
    public class MatchesController : ApiControllerBase
    {
        private readonly IMatchLogService _matches;

        public MatchesController(IMatchLogService matches)
        {
            _matches = matches;
        }

        [HttpGet]
        public async Task<IActionResult> GetMine() => Ok(await _matches.GetMineAsync(User.GetUserId()));

        [HttpGet("options")]
        public async Task<IActionResult> GetOptions() => Ok(await _matches.GetOptionsAsync(User.GetUserId()));

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateMatchRequest request) =>
            ToActionResult(await _matches.CreateAsync(User.GetUserId(), request));

        [HttpPost("{id:guid}/confirm")]
        public async Task<IActionResult> Confirm(Guid id, [FromBody] ConfirmMatchRequest request) =>
            ToActionResult(await _matches.ConfirmAsync(User.GetUserId(), id, request.Confirm));

        [HttpPost("rank")]
        public async Task<IActionResult> SetRank([FromBody] SetRankRequest request) =>
            ToActionResult(await _matches.SetRankAsync(User.GetUserId(), request.GameId, request.Rank));
    }
}
