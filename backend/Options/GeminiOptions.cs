namespace Blush.Api.Options
{
    // Đọc từ mục "Gemini" trong appsettings.json.
    // Key KHÔNG ghi vào appsettings.json (sẽ bị đẩy lên GitHub) mà đặt bằng:
    //   dotnet user-secrets set "Gemini:ApiKey" "<key từ aistudio.google.com>"
    // Chưa có key thì các tính năng AI trả lỗi 503, app tự dùng gợi ý có sẵn.
    public class GeminiOptions
    {
        public const string SectionName = "Gemini";

        public string ApiKey { get; set; } = string.Empty;
        public string Model { get; set; } = "gemini-3.5-flash-lite";
        public int TimeoutSeconds { get; set; } = 20;

        // Số lượt dùng AI mỗi ngày (giờ Việt Nam) theo gói. 0 = không giới hạn số lượt.
        public int FreeDailyLimit { get; set; } = 3;
        public int BasicDailyLimit { get; set; } = 10;
        public int ProDailyLimit { get; set; } = 0;

        // Hạn mức tokens mỗi tháng của người chưa mua VIP (gói VIP dùng VipPackages.AiTokenLimit)
        public int FreeMonthlyTokens { get; set; } = 20000;

        public bool IsConfigured => !string.IsNullOrWhiteSpace(ApiKey);
    }
}
