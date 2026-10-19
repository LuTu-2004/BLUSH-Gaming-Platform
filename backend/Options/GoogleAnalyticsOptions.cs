namespace Blush.Api.Options
{
    // Đọc từ mục "GoogleAnalytics" trong appsettings.json. Dùng cho trang Google Analytics của Admin.
    // Đăng nhập GA bằng chính file key Service account của Firebase (Firebase:CredentialsPath), nên cần:
    //   1. analytics.google.com -> Admin -> Property access management: thêm email service account
    //      (client_email trong file key) với vai trò Viewer
    //   2. Admin -> Property details: copy Property ID (dãy số, KHÁC mã "G-...") vào PropertyId
    public class GoogleAnalyticsOptions
    {
        public const string SectionName = "GoogleAnalytics";

        public string PropertyId { get; set; } = string.Empty;

        /// Giữ kết quả bao lâu trước khi hỏi GA lại (GA giới hạn số lần gọi mỗi ngày, số liệu cũng chỉ cập nhật theo giờ)
        public int CacheMinutes { get; set; } = 10;

        public bool IsConfigured => !string.IsNullOrWhiteSpace(PropertyId);
    }
}
