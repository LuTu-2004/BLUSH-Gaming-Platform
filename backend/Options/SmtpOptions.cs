namespace Blush.Api.Options
{
    // Đọc từ mục "Smtp" trong appsettings.json.
    // Mật khẩu KHÔNG ghi vào appsettings.json (sẽ bị đẩy lên GitHub) mà đặt bằng:
    //   dotnet user-secrets set "Smtp:Password" "<mật khẩu ứng dụng Gmail>"
    public class SmtpOptions
    {
        public const string SectionName = "Smtp";

        public string Host { get; set; } = "smtp.gmail.com";
        public int Port { get; set; } = 587;
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FromEmail { get; set; } = string.Empty;
        public string FromName { get; set; } = "BLUSH";

        public bool IsConfigured => !string.IsNullOrWhiteSpace(Username) && !string.IsNullOrWhiteSpace(Password);
    }
}
