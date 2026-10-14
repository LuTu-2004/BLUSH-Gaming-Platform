namespace Blush.Api.Options
{
    // Đọc từ mục "Firebase" trong appsettings.json.
    // File key Service account (Firebase -> Project settings -> Service accounts) là BÍ MẬT:
    // cất ngoài repo rồi trỏ tới bằng
    //   dotnet user-secrets set "Firebase:CredentialsPath" "D:\keys\blush-firebase-adminsdk.json"
    // Chưa có thì không gửi thông báo đẩy, thông báo trong app (SignalR) vẫn chạy bình thường.
    public class FirebaseOptions
    {
        public const string SectionName = "Firebase";

        public string CredentialsPath { get; set; } = string.Empty;

        public bool IsConfigured => !string.IsNullOrWhiteSpace(CredentialsPath);
    }
}
