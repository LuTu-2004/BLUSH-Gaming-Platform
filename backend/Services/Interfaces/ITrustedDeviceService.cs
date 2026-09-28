namespace Blush.Api.Services.Interfaces
{
    public interface ITrustedDeviceService
    {
        /// Tạo thiết bị tin cậy (30 ngày). Trả về token gốc để app lưu lại.
        Task<string> CreateAsync(Guid userId, string? deviceName);

        /// Token app gửi lên có phải thiết bị tin cậy còn hạn của user này không.
        Task<bool> IsTrustedAsync(Guid userId, string? deviceToken);

        /// Hủy toàn bộ thiết bị tin cậy (khi tắt 2 bước hoặc đổi mật khẩu).
        Task RevokeAllAsync(Guid userId);
    }
}
