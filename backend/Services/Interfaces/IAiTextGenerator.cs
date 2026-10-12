namespace Blush.Api.Services.Interfaces
{
    public record AiTextResult(string Text, int TokensUsed);

    // Gọi mô hình ngôn ngữ (hiện là Gemini). Tách interface để test thay bằng bản giả, sau này đổi nhà cung cấp chỉ sửa 1 class.
    public interface IAiTextGenerator
    {
        bool IsConfigured { get; }

        /// Trả về null nếu dịch vụ AI lỗi / quá tải (đã thử lại 1 lần) -> nơi gọi dùng nội dung dự phòng.
        /// [jsonOutput] = true thì yêu cầu mô hình trả JSON. [temperature] thấp = trả lời ổn định (chấm điểm), cao = đa dạng (gợi ý câu).
        Task<AiTextResult?> GenerateAsync(string systemPrompt, string userPrompt, bool jsonOutput, double temperature = 0.8, CancellationToken ct = default);
    }
}
