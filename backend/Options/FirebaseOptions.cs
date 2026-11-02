using Google.Apis.Auth.OAuth2;

namespace Blush.Api.Options
{
    // Đọc từ mục "Firebase" trong appsettings.json.
    // File key Service account (Firebase -> Project settings -> Service accounts) là BÍ MẬT, đặt 1 trong 2 cách:
    //   - Máy dev: cất file ngoài repo rồi trỏ tới
    //       dotnet user-secrets set "Firebase:CredentialsPath" "D:\keys\blush-firebase-adminsdk.json"
    //   - Server (Azure...): không có ổ D: của máy dev -> dán NGUYÊN nội dung file JSON vào cấu hình Firebase__CredentialsJson
    // Đặt cả 2 thì dùng CredentialsJson. Chưa có thì không gửi thông báo đẩy, thông báo trong app (SignalR) vẫn chạy bình thường.
    public class FirebaseOptions
    {
        public const string SectionName = "Firebase";

        public string CredentialsPath { get; set; } = string.Empty;
        public string CredentialsJson { get; set; } = string.Empty;

        public bool IsConfigured => !string.IsNullOrWhiteSpace(CredentialsJson) || !string.IsNullOrWhiteSpace(CredentialsPath);

        /// Có khóa nhưng là đường dẫn file không tồn tại (VD chép cấu hình máy dev lên server)
        public bool IsMissingFile => string.IsNullOrWhiteSpace(CredentialsJson) && !string.IsNullOrWhiteSpace(CredentialsPath) && !File.Exists(CredentialsPath);

        /// Khóa Service account dùng chung cho thông báo đẩy (FCM) và Google Analytics Data API
        public ServiceAccountCredential LoadServiceAccount() => string.IsNullOrWhiteSpace(CredentialsJson)
            ? CredentialFactory.FromFile<ServiceAccountCredential>(CredentialsPath)
            : CredentialFactory.FromJson<ServiceAccountCredential>(CredentialsJson);
    }
}
