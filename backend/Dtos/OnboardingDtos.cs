using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // ── Dữ liệu để app vẽ các bước onboarding ─────────────────────
    public class OnboardingOptionsDto
    {
        public List<GameOptionDto> Games { get; set; } = new();
        public List<OptionDto> Purposes { get; set; } = new();
        public List<OptionDto> PlayTimes { get; set; } = new();
        public List<RegionOptionDto> Regions { get; set; } = new();
        public List<OptionDto> Zones { get; set; } = new(); // miền: để nhóm danh sách tỉnh và lọc bảng xếp hạng
        public List<HobbyOptionDto> Hobbies { get; set; } = new();
    }

    public class GameOptionDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Genre { get; set; }
        public List<string> Positions { get; set; } = new(); // gợi ý vị trí, rỗng = game không chia vị trí
        public List<string> Ranks { get; set; } = new(); // thấp -> cao, rỗng = game không có bảng rank
    }

    public class OptionDto
    {
        public string Code { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
    }

    public class RegionOptionDto : OptionDto
    {
        public string Zone { get; set; } = string.Empty; // North | Central | South | Overseas
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
        [Required(ErrorMessage = "Vui lòng chọn khu vực.")] // mã tỉnh/thành trong GameCatalog.Regions, kiểm tra ở OnboardingService
        public string Region { get; set; } = string.Empty;

        public bool? UsesMic { get; set; } // null = tùy trận

        // Bước 4: sở thích, mô tả đồng đội mong muốn
        [MaxLength(8, ErrorMessage = "Chọn tối đa 8 sở thích.")]
        public List<int> HobbyIds { get; set; } = new();

        [MaxLength(300, ErrorMessage = "Mô tả tối đa 300 ký tự.")]
        public string? TeammateWish { get; set; }

        // Dạng "2006-01-10". Chỉ bắt buộc với tài khoản chưa có ngày sinh (đăng nhập Google lần đầu).
        // Đã có ngày sinh thì backend bỏ qua trường này (không cho đổi ngày sinh để lách tuổi).
        public DateOnly? DateOfBirth { get; set; }
    }

    // ── Biết BLUSH qua đâu (hỏi 1 lần sau khảo sát) ─────────────────
    // GET api/onboarding/source: Source = null nghĩa là chưa trả lời
    public class AcquisitionSourceDto
    {
        public string? Source { get; set; }
    }

    // POST api/onboarding/source
    public class SaveAcquisitionSourceRequest
    {
        [Required(ErrorMessage = "Vui lòng chọn 1 nguồn.")]
        public string Source { get; set; } = string.Empty; // google | facebook | tiktok | youtube | friend | other
    }

    public class OnboardingGameDto
    {
        [Range(1, int.MaxValue, ErrorMessage = "Game không hợp lệ.")]
        public int GameId { get; set; }

        [MaxLength(50, ErrorMessage = "Vị trí tối đa 50 ký tự.")]
        public string? Position { get; set; }

        [MaxLength(50, ErrorMessage = "Rank tối đa 50 ký tự.")]
        public string? Rank { get; set; } // null = chưa khai; dùng chung với rank ở Nhật ký trận đấu

        [Required(ErrorMessage = "Vui lòng chọn mục đích chơi.")]
        [RegularExpression("^(Tryhard|Fun|Event)$", ErrorMessage = "Mục đích chơi không hợp lệ.")]
        public string Purpose { get; set; } = string.Empty;
    }
}
