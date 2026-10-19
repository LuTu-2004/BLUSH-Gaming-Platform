using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // GET api/ratings/me - đánh giá của mình (chưa đánh giá thì Stars = null)
    public class MyRatingDto
    {
        public int? Stars { get; set; }
        public string? Comment { get; set; }
        public DateTime? UpdatedAt { get; set; }

        /// true = chưa đánh giá và đã dùng app đủ lâu -> app tự hỏi 1 lần (bấm "Để sau" thì app tự nhớ, không hỏi lại)
        public bool ShouldAsk { get; set; }
    }

    // POST api/ratings/me - gửi / sửa đánh giá
    public class SubmitRatingRequest
    {
        [Range(1, 5, ErrorMessage = "Số sao phải từ 1 đến 5.")]
        public int Stars { get; set; }

        [MaxLength(1000, ErrorMessage = "Góp ý tối đa 1000 ký tự.")]
        public string? Comment { get; set; }
    }

    // ── Admin: lịch sử đánh giá ─────────────────────────────────

    // 1 dòng trong trang Lịch sử đánh giá
    public class AdminRatingDto
    {
        public Guid UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public int Stars { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; } // lần sửa gần nhất (= CreatedAt nếu chưa sửa)
    }

    // Số liệu trên toàn bộ đánh giá (không theo bộ lọc): box Đánh giá ở Tổng quan + đầu trang Lịch sử
    public class AdminRatingStatsDto
    {
        public int Count { get; set; }
        public double? Average { get; set; } // null = chưa có đánh giá
        public int[] ByStars { get; set; } = new int[5]; // [0] = số lượt 1 sao ... [4] = 5 sao
    }

    public class AdminRatingListDto : PagedResult<AdminRatingDto>
    {
        public AdminRatingStatsDto Stats { get; set; } = new();
    }
}
