namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Zones] - cộng đồng theo game + mục đích chơi. IsVipOnly = Zone kín cho BLUSH Pass Pro.
    public class Zone
    {
        public int Id { get; set; }
        public int GameId { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public string Purpose { get; set; } = GamePurpose.Fun;
        public bool IsVipOnly { get; set; }
        public string? Description { get; set; }

        public Game Game { get; set; } = null!;
    }

    // Bảng [UserZones] - thành viên Zone
    public class UserZone
    {
        public Guid UserId { get; set; }
        public int ZoneId { get; set; }
        public DateTime JoinedAt { get; set; }
    }

    // Bảng [Posts] - bài đăng trong Zone. RemovedAt != null = đã gỡ (người đăng hoặc Staff)
    public class Post
    {
        public Guid Id { get; set; }
        public int ZoneId { get; set; }
        public Guid AuthorId { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? RemovedAt { get; set; }
        public Guid? RemovedBy { get; set; }
    }

    public class PostLike
    {
        public Guid PostId { get; set; }
        public Guid UserId { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class PostComment
    {
        public Guid Id { get; set; }
        public Guid PostId { get; set; }
        public Guid AuthorId { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? RemovedAt { get; set; }
    }
}
