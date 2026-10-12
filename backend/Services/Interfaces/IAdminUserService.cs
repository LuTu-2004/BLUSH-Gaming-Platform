using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IAdminUserService
    {
        Task<AdminUserListDto> GetUsersAsync(string? search, string? role, string? status, int page, int pageSize);

        /// Khóa vĩnh viễn / tạm khóa N ngày / mở khóa. Không tự khóa chính mình.
        Task<ServiceResult<AdminUserDto>> UpdateStatusAsync(Guid adminId, Guid userId, UpdateUserStatusRequest request);

        /// Đổi vai trò User / Staff / Admin. Không tự đổi vai trò của chính mình.
        Task<ServiceResult<AdminUserDto>> UpdateRoleAsync(Guid adminId, Guid userId, UpdateUserRoleRequest request);
    }
}
