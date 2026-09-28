namespace Blush.Api.DataAccess.Entities
{
    // Bảng [UserLogins] - liên kết tài khoản với Google (sau này thêm Facebook...)
    public class UserLogin
    {
        public const string Google = "Google";

        public string Provider { get; set; } = string.Empty;
        public string ProviderKey { get; set; } = string.Empty; // claim "sub" của Google
        public Guid UserId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
