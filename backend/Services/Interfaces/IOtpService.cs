using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IOtpService
    {
        /// Tạo mã 6 số mới (hủy mã cũ cùng mục đích) và gửi qua email.
        Task<ServiceResult<bool>> SendAsync(User user, string purpose);

        /// Kiểm tra mã. Đúng thì đánh dấu đã dùng. Sai quá 5 lần hoặc hết hạn -> phải xin mã mới.
        Task<ServiceResult<bool>> VerifyAsync(Guid userId, string purpose, string code);
    }
}
