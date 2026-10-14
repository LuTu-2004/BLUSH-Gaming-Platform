namespace Blush.Api.Options
{
    // Đọc từ mục "Storage" trong appsettings.json: nơi lưu file người dùng tải lên (ảnh đại diện).
    // Lưu trên ổ đĩa của máy chạy backend, phát ra ở đường dẫn /uploads/...
    // Deploy: thư mục này phải nằm trên ổ đĩa giữ được file (VPS có, một số dịch vụ PaaS xóa sạch mỗi lần deploy).
    public class StorageOptions
    {
        public const string SectionName = "Storage";

        /// Thư mục lưu file, tương đối so với thư mục backend (hoặc đường dẫn tuyệt đối)
        public string LocalPath { get; set; } = "uploads";

        /// Dung lượng ảnh đại diện tối đa khi tải lên (byte). Lưu thật chỉ ~50KB vì backend thu nhỏ về 512x512.
        public long MaxAvatarBytes { get; set; } = 5 * 1024 * 1024;
    }
}
