using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Blush.Api.Controllers
{
    // ============================================================
    // LAYER 1: PRESENTATION LAYER - Bài đăng + bình luận (cần token)
    //   DELETE api/posts/{id}              - Gỡ bài (người đăng / Staff / Admin)
    //   POST   api/posts/{id}/like         - Thả tim       DELETE api/posts/{id}/like - Bỏ tim
    //   GET    api/posts/{id}/comments     - Bình luận (cũ -> mới)
    //   POST   api/posts/{id}/comments     - Bình luận { content }
    //   DELETE api/comments/{id}           - Xóa bình luận (người viết / Staff / Admin)
    // ============================================================
    [Authorize]
    public class PostsController : ApiControllerBase
    {
        private readonly IFeedService _feed;

        public PostsController(IFeedService feed)
        {
            _feed = feed;
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id) => ToActionResult(await _feed.DeletePostAsync(User.GetUserId(), id, User.IsModerator()));

        [HttpPost("{id:guid}/like")]
        public async Task<IActionResult> Like(Guid id) => ToActionResult(await _feed.SetLikeAsync(User.GetUserId(), id, true, User.IsModerator()));

        [HttpDelete("{id:guid}/like")]
        public async Task<IActionResult> Unlike(Guid id) => ToActionResult(await _feed.SetLikeAsync(User.GetUserId(), id, false, User.IsModerator()));

        [HttpGet("{id:guid}/comments")]
        public async Task<IActionResult> GetComments(Guid id) => ToActionResult(await _feed.GetCommentsAsync(User.GetUserId(), id, User.IsModerator()));

        [HttpPost("{id:guid}/comments")]
        public async Task<IActionResult> AddComment(Guid id, [FromBody] CreateCommentRequest request) =>
            ToActionResult(await _feed.AddCommentAsync(User.GetUserId(), id, request.Content, User.IsModerator()));

        [HttpDelete("/api/comments/{id:guid}")]
        public async Task<IActionResult> DeleteComment(Guid id) => ToActionResult(await _feed.DeleteCommentAsync(User.GetUserId(), id, User.IsModerator()));
    }
}
