namespace Blush.Api.DataAccess.Entities
{
    // Bảng [UserBlocks] - BlockerId đã chặn BlockedId. Tác dụng cả 2 chiều: không chat, không gợi ý ghép đội.
    public class UserBlock
    {
        public Guid BlockerId { get; set; }
        public Guid BlockedId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
