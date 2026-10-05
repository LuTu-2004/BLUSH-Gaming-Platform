using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // ── Dữ liệu để app vẽ các bước onboarding ─────────────────────
    public class OnboardingOptionsDto
    {
        public List<GameOptionDto> Games { get; set; } = new();
        public List<OptionDto> Purposes { get; set; } = new();
        public List<OptionDto> PlayTimes { get; set; } = new();
        public List<OptionDto> Regions { get; set; } = new();
        public List<HobbyOptionDto> Hobbies { get; set; } = new();
    }

    public class GameOptionDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Genre { get; set; }
        public List<string> Positions { get; set; } = new(); // gợi ý vị trí, rỗng = game không chia vị trí
    }

    public class OptionDto
    {
        public string Code { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
    }

    public class HobbyOptionDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    // ── Câu trả lời onboarding: app gửi lên khi lưu, backend trả về khi mở lại để sửa ──
    public class OnboardingRequest
    {
        // Bước 1 (bắt buộc): game đang chơi
        [Required(ErrorMessage = "Vui lòng chọn ít nhất 1 game.")]
        [MinLength(1, ErrorMessage = "Vui lòng chọn ít nhất 1 game.")]
        [MaxLength(6, ErrorMessage = "Chọn tối đa 6 game.")]
        public List<OnboardingGameDto> Games { get; set; } = new();

        // Bước 2: khung giờ (PlayTimeSlot)
        public List<string> PlayTimes { get; set; } = new();

        // Bước 3 (bắt buộc): khu vực + mic
        [Required(ErrorMessage = "Vui lòng chọn khu vực.")]
        [RegularExpression("^(HCM|HN)$", ErrorMessage = "Khu vực không hợp lệ.")]
        public string Region { get; set; } = string.Empty;

        public bool? UsesMic { get; set; } // null = tùy trận

        // Bước 4: sở thích, mô tả đồng đội mong muốn
        [MaxLength(8, ErrorMessage = "Chọn tối đa 8 sở thích.")]
        public List<int> HobbyIds { get; set; } = new();

        [MaxLength(300, ErrorMessage = "Mô tả tối đa 300 ký tự.")]
        public string? TeammateWish { get; set; }
    }

    public class OnboardingGameDto
    {
        [Range(1, int.MaxValue, ErrorMessage = "Game không hợp lệ.")]
        public int GameId { get; set; }

        [MaxLength(50, ErrorMessage = "Vị trí tối đa 50 ký tự.")]
        public string? Position { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn mục đích chơi.")]
        [RegularExpression("^(Tryhard|Fun|Event)$", ErrorMessage = "Mục đích chơi không hợp lệ.")]
        public string Purpose { get; set; } = string.Empty;
    }
}
