namespace Blush.Api.DataAccess.Entities
{
    // Bảng [TrustedDevices] - thiết bị đã chọn "Tin cậy 30 ngày" (bỏ qua mã 2 bước)
    public class TrustedDevice
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string TokenHash { get; set; } = string.Empty;
        public string? DeviceName { get; set; }
        public DateTime ExpiresAt { get; set; }
        public DateTime? LastUsedAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
