using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Khảo sát sau đăng ký (dữ liệu để ghép đội)
    // ============================================================
    public interface IOnboardingService
    {
        /// Danh sách game, khung giờ, khu vực, sở thích để app vẽ các bước
        Task<OnboardingOptionsDto> GetOptionsAsync();

        /// Câu trả lời đã lưu (để sửa lại trong Hồ sơ)
        Task<OnboardingRequest> GetAnswersAsync(Guid userId);

        /// Lưu câu trả lời (ghi đè lần trước) và đánh dấu đã hoàn tất onboarding
        Task<ServiceResult<UserDto>> SaveAsync(Guid userId, OnboardingRequest request);
    }
}
