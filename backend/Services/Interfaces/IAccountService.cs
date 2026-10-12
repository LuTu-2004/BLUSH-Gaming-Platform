using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IAccountService
    {
        /// Người dùng tự xóa tài khoản (Google Play bắt buộc). Xem AccountService để biết dữ liệu nào bị xóa / giữ lại.
        Task<ServiceResult<MessageResponse>> DeleteAsync(Guid userId, DeleteAccountRequest request);
    }
}
