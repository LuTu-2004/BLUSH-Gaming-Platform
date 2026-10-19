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
}
