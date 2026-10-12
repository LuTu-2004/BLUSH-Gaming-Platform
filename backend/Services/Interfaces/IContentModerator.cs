namespace Blush.Api.Services.Interfaces
{
    /// Kết quả AI chấm: [Score] 0-100, [Category] Toxic | Harassment | Scam | Spam | None, [Summary] 1 câu cho Staff đọc
    public record ModerationVerdict(short Score, string Category, string Summary);

    // AI hỗ trợ kiểm duyệt: chỉ chấm điểm để Staff ưu tiên + tạm ẩn nội dung quá nặng chờ Staff duyệt.
    // AI KHÔNG BAO GIỜ tự cảnh báo / khóa tài khoản.
    public interface IContentModerator
    {
        /// Từ điểm này trở lên: bài viết / bình luận bị tạm ẩn chờ Staff duyệt
        const int HoldThreshold = 80;

        /// null = AI chưa bật / lỗi -> nơi gọi xử lý như bình thường (không chặn người dùng vì AI hỏng)
        Task<ModerationVerdict?> ScoreAsync(string content);

        /// Gom bằng chứng (tin nhắn người bị báo cáo gửi người báo cáo, bài đăng / bình luận gần đây) rồi chấm, lưu vào báo cáo
        Task<bool> ScoreReportAsync(int reportId);

        /// Chấm các báo cáo đang chờ chưa có điểm AI (báo cáo gửi trước khi có tính năng / lúc AI lỗi). Trả về số báo cáo đã chấm.
        Task<int> ScorePendingReportsAsync(int max);
    }
}
