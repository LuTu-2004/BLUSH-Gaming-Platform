using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IUserService
    {
        /// Lấy thông tin người dùng (gộp Users + UserProfiles + Roles + VIP). Trả về null nếu không có.
        Task<UserDto?> GetUserDtoAsync(Guid userId);

        /// Lưu giới thiệu + 2 câu hỏi cá nhân trong tab Hồ sơ
        Task<ServiceResult<UserDto>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request);

        /// Đổi ảnh đại diện: ảnh JPEG/PNG/WebP, thu nhỏ về 512x512, bỏ thông tin GPS / máy chụp trong ảnh
        Task<ServiceResult<UserDto>> UpdateAvatarAsync(Guid userId, Stream image, long length, CancellationToken ct = default);

        /// Gỡ ảnh đại diện -> app hiện lại chữ cái / emoji
        Task<ServiceResult<UserDto>> RemoveAvatarAsync(Guid userId);
    }
}
