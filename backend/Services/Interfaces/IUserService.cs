using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IUserService
    {
        /// Lấy thông tin người dùng (gộp Users + UserProfiles + Roles + VIP). Trả về null nếu không có.
        Task<UserDto?> GetUserDtoAsync(Guid userId);
    }
}
