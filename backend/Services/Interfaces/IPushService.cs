namespace Blush.Api.Services.Interfaces
{
    // Thông báo đẩy ra điện thoại (Firebase Cloud Messaging), hiện kể cả khi app đang tắt.
    public interface IPushService
    {
        /// Lưu mã FCM của điện thoại cho [userId]. Mã đang thuộc tài khoản khác (đổi tài khoản trên cùng máy) thì chuyển sang.
        Task RegisterAsync(Guid userId, string token, string platform);

        /// Gỡ mã khi đăng xuất
        Task UnregisterAsync(Guid userId, string token);

        /// Xếp hàng gửi, trả về ngay (gửi ở nền, không làm chậm request). Chưa cấu hình Firebase thì bỏ qua.
        /// [link]: nơi mở khi bấm ('chat:<userId>', 'zone:2', 'vip'...). [tag]: cùng tag thì thông báo mới thay thông báo cũ.
        void Enqueue(Guid userId, string title, string? body, string? link, string? tag = null);
    }
}
