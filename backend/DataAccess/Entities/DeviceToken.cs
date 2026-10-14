namespace Blush.Api.DataAccess.Entities
{
    // Bảng [DeviceTokens] - mã Firebase Cloud Messaging của 1 điện thoại đang đăng nhập (Token là duy nhất)
    public class DeviceToken
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Token { get; set; } = string.Empty;
        public string Platform { get; set; } = string.Empty; // 'android' | 'ios' | 'web'
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
