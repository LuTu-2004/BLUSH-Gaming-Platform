using System.Text.RegularExpressions;
using Blush.Api.Services.Interfaces;

namespace Blush.Api.Services.Implementations
{
    // Dùng khi CHƯA cấu hình SMTP (lúc dev): không gửi mail thật mà in nội dung ra terminal backend.
    // Nhìn terminal đang chạy `dotnet run` để lấy mã OTP.
    public class ConsoleEmailSender : IEmailSender
    {
        private readonly ILogger<ConsoleEmailSender> _logger;

        public ConsoleEmailSender(ILogger<ConsoleEmailSender> logger)
        {
            _logger = logger;
        }

        public Task SendAsync(string toEmail, string subject, string htmlBody)
        {
            var text = Regex.Replace(htmlBody, "<[^>]+>", " ");
            text = Regex.Replace(text, @"\s+", " ").Trim();
            _logger.LogWarning("📧 [EMAIL GIẢ LẬP - chưa cấu hình SMTP] Tới: {To} | {Subject} | {Text}", toEmail, subject, text);
            return Task.CompletedTask;
        }
    }
}
