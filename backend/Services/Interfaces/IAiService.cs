using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // Tính năng AI cho người dùng. Mỗi lần gọi thành công trừ 1 lượt + số tokens theo gói (Free / Basic / Pro).
    // Lỗi: 429 + code AI_QUOTA_EXCEEDED (hết lượt), 503 + code AI_UNAVAILABLE (chưa cấu hình / Gemini đang lỗi, không trừ lượt).
    public interface IAiService
    {
        Task<AiUsageDto> GetUsageAsync(Guid userId);

        /// 3 câu gợi ý trong phòng chat: chưa nhắn gì -> câu mở đầu, đã nhắn -> gợi ý nói tiếp
        Task<ServiceResult<AiSuggestionsDto>> SuggestMessagesAsync(Guid userId, Guid roomId);

        /// Vì sao mình và [otherUserId] hợp nhau (đọc cả phần "muốn đồng đội như thế nào")
        Task<ServiceResult<AiExplanationDto>> ExplainMatchAsync(Guid userId, Guid otherUserId);

        /// Báo cáo 1 câu trả lời AI không phù hợp (chỉ người nhận câu trả lời đó)
        Task<ServiceResult<MessageResponse>> ReportAsync(Guid userId, Guid logId, string? reason);
    }
}
