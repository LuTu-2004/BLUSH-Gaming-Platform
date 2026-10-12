using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // Zone (cộng đồng theo game + mục đích) và Feed (bài đăng, thả tim, bình luận).
    // [isModerator] = Staff/Admin: xem mọi Zone, gỡ bài / bình luận của người khác.
    public interface IFeedService
    {
        Task<List<ZoneDto>> GetZonesAsync(Guid userId, bool isModerator);
        Task<ServiceResult<ZoneDto>> JoinAsync(Guid userId, int zoneId, bool isModerator);
        Task<ServiceResult<ZoneDto>> LeaveAsync(Guid userId, int zoneId, bool isModerator);

        /// Xếp vào Zone theo game + mục đích sau khi lưu khảo sát (không rời Zone đã tự tham gia)
        Task AssignZonesFromOnboardingAsync(Guid userId);

        /// [zoneId] null = bảng tin gồm các Zone mình đã tham gia. [before] = tải bài cũ hơn.
        Task<ServiceResult<List<PostDto>>> GetPostsAsync(Guid userId, int? zoneId, DateTime? before, bool isModerator);
        Task<ServiceResult<PostDto>> CreatePostAsync(Guid userId, int zoneId, string content, bool isModerator);
        Task<ServiceResult<MessageResponse>> DeletePostAsync(Guid userId, Guid postId, bool isModerator);
        Task<ServiceResult<LikeResultDto>> SetLikeAsync(Guid userId, Guid postId, bool like, bool isModerator);

        Task<ServiceResult<List<CommentDto>>> GetCommentsAsync(Guid userId, Guid postId, bool isModerator);
        Task<ServiceResult<CommentDto>> AddCommentAsync(Guid userId, Guid postId, string content, bool isModerator);
        Task<ServiceResult<MessageResponse>> DeleteCommentAsync(Guid userId, Guid commentId, bool isModerator);
    }
}
