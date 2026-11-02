namespace Blush.Api.DataAccess.Entities
{
    // Bảng [AppRatings] - đánh giá app BLUSH 1-5 sao, mỗi người 1 dòng (UserId là duy nhất)
    public class AppRating
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public byte Stars { get; set; } // 1-5
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; } // lần đánh giá gần nhất
    }
}
