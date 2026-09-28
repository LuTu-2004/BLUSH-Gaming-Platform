namespace Blush.Api.Options
{
    // Đọc từ mục "GoogleAuth" trong appsettings.json
    public class GoogleAuthOptions
    {
        public const string SectionName = "GoogleAuth";

        // "Web client ID" tạo trên Google Cloud Console (dạng xxx.apps.googleusercontent.com).
        // App Flutter cũng dùng đúng ID này làm serverClientId.
        public string WebClientId { get; set; } = string.Empty;
    }
}
