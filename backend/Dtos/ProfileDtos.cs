using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // Form "Hồ sơ của bạn" trong tab Hồ sơ. Để trống = xóa câu trả lời.
    public class UpdateProfileRequest
    {
        [MaxLength(500, ErrorMessage = "Giới thiệu tối đa 500 ký tự.")]
        public string? Bio { get; set; }

        [MaxLength(500, ErrorMessage = "Câu trả lời tối đa 500 ký tự.")]
        public string? SundayAnswer { get; set; }

        [MaxLength(500, ErrorMessage = "Câu trả lời tối đa 500 ký tự.")]
        public string? OverthinkAnswer { get; set; }
    }
}
