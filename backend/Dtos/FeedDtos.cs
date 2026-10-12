using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    public class ZoneDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int GameId { get; set; }
        public string GameName { get; set; } = string.Empty;
        public string Purpose { get; set; } = string.Empty;
        public string PurposeLabel { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsVipOnly { get; set; } // Zone kín: chỉ BLUSH Pass Pro
        public int MemberCount { get; set; }
        public bool IsMember { get; set; }
        public bool CanAccess { get; set; } // false = Zone kín mà chưa có gói Pro
    }

    public class FeedAuthorDto
    {
        public Guid Id { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string AvatarEmoji { get; set; } = "🎮";
        public string? AvatarUrl { get; set; }
        public bool IsVip { get; set; }
    }

    public class PostDto
    {
        public Guid Id { get; set; }
        public int ZoneId { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public FeedAuthorDto Author { get; set; } = new();
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public int LikeCount { get; set; }
        public int CommentCount { get; set; }
        public bool LikedByMe { get; set; }
        public bool CanDelete { get; set; } // người đăng hoặc Staff/Admin
    }

    public class CommentDto
    {
        public Guid Id { get; set; }
        public Guid PostId { get; set; }
        public FeedAuthorDto Author { get; set; } = new();
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool CanDelete { get; set; }
    }

    public class CreatePostRequest
    {
        [Required(ErrorMessage = "Bài viết trống.")]
        [MaxLength(1000, ErrorMessage = "Bài viết tối đa 1000 ký tự.")]
        public string Content { get; set; } = string.Empty;
    }

    public class CreateCommentRequest
    {
        [Required(ErrorMessage = "Bình luận trống.")]
        [MaxLength(500, ErrorMessage = "Bình luận tối đa 500 ký tự.")]
        public string Content { get; set; } = string.Empty;
    }

    public class LikeResultDto
    {
        public bool Liked { get; set; }
        public int LikeCount { get; set; }
    }
}
