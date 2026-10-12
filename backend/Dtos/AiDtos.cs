using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // Hạn mức AI của người đang đăng nhập
    public class AiUsageDto
    {
        public string Tier { get; set; } = "Free"; // Free | Basic | Pro
        public int UsedToday { get; set; }
        public int? DailyLimit { get; set; } // null = không giới hạn số lượt
        public int TokensUsedThisMonth { get; set; }
        public int MonthlyTokenLimit { get; set; }
    }

    // Gợi ý câu nhắn trong phòng chat
    public class AiSuggestionsDto
    {
        public Guid LogId { get; set; } // dùng để báo cáo câu trả lời không phù hợp
        public List<string> Suggestions { get; set; } = new();
        public AiUsageDto Usage { get; set; } = new();
    }

    // AI giải thích vì sao 2 người hợp nhau
    public class AiExplanationDto
    {
        public Guid LogId { get; set; }
        public string Explanation { get; set; } = string.Empty;
        public AiUsageDto Usage { get; set; } = new();
    }

    public class ReportAiRequest
    {
        [MaxLength(500, ErrorMessage = "Lý do tối đa 500 ký tự.")]
        public string? Reason { get; set; }
    }
}
