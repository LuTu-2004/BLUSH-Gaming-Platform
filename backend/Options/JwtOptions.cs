namespace Blush.Api.Options
{
    // Đọc từ mục "Jwt" trong appsettings.json
    public class JwtOptions
    {
        public const string SectionName = "Jwt";

        public string Issuer { get; set; } = string.Empty;
        public string Audience { get; set; } = string.Empty;
        public string SigningKey { get; set; } = string.Empty; // tối thiểu 32 ký tự
        public int ExpiryDays { get; set; } = 7;
    }
}
