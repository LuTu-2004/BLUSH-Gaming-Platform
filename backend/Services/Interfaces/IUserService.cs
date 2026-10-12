using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IUserService
    {
        /// Lấy thông tin người dùng (gộp Users + UserProfiles + Roles + VIP). Trả về null nếu không có.
        Task<UserDto?> GetUserDtoAsync(Guid userId);

        /// Lưu giới thiệu + 2 câu hỏi cá nhân trong tab Hồ sơ
        Task<ServiceResult<UserDto>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request);
    }
}
