using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Zone + Feed (cần token)
    //   GET    api/zones                     - Danh sách Zone (đã tham gia chưa, có vào được không)
    //   POST   api/zones/{id}/join           - Tham gia (Zone kín: BLUSH Pass Pro)
    //   DELETE api/zones/{id}/join           - Rời Zone
    //   GET    api/zones/{id}/posts?before=  - Bài trong Zone (mới -> cũ, 20 bài/lần)
    //   POST   api/zones/{id}/posts          - Đăng bài { content } (phải là thành viên)
    //   GET    api/zones/feed?before=        - Bảng tin: bài từ các Zone mình tham gia
    // ============================================================
    [Authorize]
    public class ZonesController : ApiControllerBase
    {
        private readonly IFeedService _feed;

        public ZonesController(IFeedService feed)
        {
            _feed = feed;
        }

        [HttpGet]
        public async Task<IActionResult> GetZones() => Ok(await _feed.GetZonesAsync(User.GetUserId(), User.IsModerator()));

        [HttpPost("{id:int}/join")]
        public async Task<IActionResult> Join(int id) => ToActionResult(await _feed.JoinAsync(User.GetUserId(), id, User.IsModerator()));

        [HttpDelete("{id:int}/join")]
        public async Task<IActionResult> Leave(int id) => ToActionResult(await _feed.LeaveAsync(User.GetUserId(), id, User.IsModerator()));

        [HttpGet("{id:int}/posts")]
        public async Task<IActionResult> GetPosts(int id, [FromQuery] DateTime? before) =>
            ToActionResult(await _feed.GetPostsAsync(User.GetUserId(), id, before, User.IsModerator()));

        [HttpPost("{id:int}/posts")]
        public async Task<IActionResult> CreatePost(int id, [FromBody] CreatePostRequest request) =>
            ToActionResult(await _feed.CreatePostAsync(User.GetUserId(), id, request.Content, User.IsModerator()));

        [HttpGet("feed")]
        public async Task<IActionResult> GetFeed([FromQuery] DateTime? before) =>
            ToActionResult(await _feed.GetPostsAsync(User.GetUserId(), null, before, User.IsModerator()));
    }
}
