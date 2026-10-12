namespace Blush.Api.DataAccess.Entities
{
    // Bảng [AiLogs] - mỗi lần gọi Gemini thành công là 1 dòng (đếm lượt + tokens theo gói, cho người dùng báo cáo câu trả lời)
    public class AiLog
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string FeatureType { get; set; } = string.Empty; // AiFeature
        public string? PromptInput { get; set; } // chỉ ghi loại yêu cầu, KHÔNG ghi nội dung hồ sơ / tin nhắn
        public string AiOutput { get; set; } = string.Empty;
        public int TokensUsed { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ReportedAt { get; set; }
        public string? ReportReason { get; set; }
    }

    // Giá trị hợp lệ của AiLogs.FeatureType (khớp CHECK trong SQL)
    public static class AiFeature
    {
        public const string ConversationStarter = "ConversationStarter"; // gợi ý câu mở đầu (chưa nhắn gì)
        public const string DeadChatRescue = "DeadChatRescue";           // gợi ý chủ đề khi đã nhắn qua lại
        public const string ProfileMatching = "ProfileMatching";         // AI giải thích vì sao 2 người hợp nhau
        public const string ZoneClassification = "ZoneClassification";   // chưa dùng (chờ tính năng Zone)
    }
}
