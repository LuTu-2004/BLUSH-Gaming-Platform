namespace Blush.Api.Services.Interfaces
{
    // Nơi lưu file người dùng tải lên. Hiện là ổ đĩa backend (LocalFileStorage);
    // muốn chuyển sang cloud (Firebase Storage, Cloudinary...) thì viết class khác cài interface này.
    public interface IFileStorage
    {
        /// Lưu file, trả về URL để lưu vào DB (VD "/uploads/avatars/abc.jpg")
        Task<string> SaveAsync(string folder, string fileName, Stream content, CancellationToken ct = default);

        /// Xóa file theo URL đã trả về từ SaveAsync. URL không phải của mình (VD ảnh Google) thì bỏ qua.
        Task DeleteAsync(string? url);
    }
}
