using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // ── Báo cáo vi phạm ───────────────────────────────────────────

    // Người chơi gửi báo cáo (POST api/reports)
    public class CreateReportRequest
    {
        [Required(ErrorMessage = "Thiếu người bị báo cáo.")]
        public Guid? ReportedUserId { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn lý do.")]
        public string ReasonCode { get; set; } = string.Empty; // ReportReason.Code

        [MaxLength(400, ErrorMessage = "Mô tả tối đa 400 ký tự.")]
        public string? Detail { get; set; }
    }

    // 1 báo cáo trong trang Kiểm duyệt
    public class ReportDto
    {
        public int Id { get; set; }
        public Guid ReporterId { get; set; }
        public string ReporterName { get; set; } = string.Empty;
        public Guid ReportedUserId { get; set; }
        public string ReportedUserName { get; set; } = string.Empty;
        public string ReportedUserEmail { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
        public string Severity { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? ActionTaken { get; set; }
        public string? ResolvedByName { get; set; }
        public DateTime? ResolvedAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class ReportStatsDto
    {
        public int Total { get; set; }
        public int Pending { get; set; }
        public int Resolved { get; set; }
    }

    public class ReportListDto : PagedResult<ReportDto>
    {
        public ReportStatsDto Stats { get; set; } = new();
    }

    public class ResolveReportRequest
    {
        [Required(ErrorMessage = "Vui lòng chọn cách xử lý.")]
        [RegularExpression("^(Warn|Suspend|Dismiss)$", ErrorMessage = "Cách xử lý không hợp lệ.")]
        public string Action { get; set; } = string.Empty;
    }

    // ── Câu hỏi phá băng ─────────────────────────────────────────

    public class IceBreakerDto
    {
        public int Id { get; set; }
        public string Category { get; set; } = string.Empty;
        public string Question { get; set; } = string.Empty;
        public string OptionA { get; set; } = string.Empty;
        public string OptionB { get; set; } = string.Empty;
        public string OptionAIcon { get; set; } = string.Empty;
        public string OptionBIcon { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class CreateIceBreakerRequest
    {
        [Required(ErrorMessage = "Vui lòng chọn loại câu hỏi.")]
        public string Category { get; set; } = string.Empty; // IceBreakerCategory

        [Required(ErrorMessage = "Vui lòng nhập câu hỏi.")]
        [MaxLength(500, ErrorMessage = "Câu hỏi tối đa 500 ký tự.")]
        public string Question { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập lựa chọn A.")]
        [MaxLength(255, ErrorMessage = "Lựa chọn tối đa 255 ký tự.")]
        public string OptionA { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập lựa chọn B.")]
        [MaxLength(255, ErrorMessage = "Lựa chọn tối đa 255 ký tự.")]
        public string OptionB { get; set; } = string.Empty;
    }

    public class SetActiveRequest
    {
        public bool IsActive { get; set; }
    }
}
