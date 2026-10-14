namespace Blush.Api.Services.Interfaces
{
    // AI đọc phần tự viết (giới thiệu + "muốn đồng đội như thế nào") ra 3 chỉ số phong cách chơi -2..2,
    // lưu vào UserProfiles để ghép đội so sánh (RuleBasedMatchingService). Chi phí hệ thống, không trừ lượt AI của người dùng.
    public interface IPlaystyleAnalyzer
    {
        /// Phân tích lại nếu đoạn văn đổi so với lần trước. Lỗi / chưa có key thì giữ chỉ số cũ. true = vừa phân tích.
        Task<bool> AnalyzeAsync(Guid userId);

        /// Phân tích các hồ sơ có viết mà chưa phân tích (VD dữ liệu cũ trước khi có tính năng). Trả về số hồ sơ đã phân tích.
        Task<int> BackfillAsync(int max);
    }
}
