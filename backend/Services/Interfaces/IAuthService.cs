using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IAuthService
    {
        /// Tạo tài khoản (chưa xác minh) và gửi mã OTP về email. Chưa trả token.
        Task<ServiceResult<MessageResponse>> RegisterAsync(RegisterRequest request);

        /// Nhập đúng mã OTP -> xác minh email và đăng nhập luôn.
        Task<ServiceResult<AuthResponse>> VerifyEmailAsync(VerifyEmailRequest request);

        Task<ServiceResult<MessageResponse>> ResendOtpAsync(ResendOtpRequest request);
        /// Bật 2 bước mà thiết bị chưa tin cậy -> gửi mã về email, trả lỗi mã TWO_FACTOR_REQUIRED.
        Task<ServiceResult<AuthResponse>> LoginAsync(LoginRequest request);

        /// Bước 2 của đăng nhập: nhập mã từ email.
        Task<ServiceResult<AuthResponse>> LoginWithTwoFactorAsync(TwoFactorLoginRequest request);

        /// Bật 2 bước - bước 1: kiểm tra mật khẩu, gửi mã xác nhận về email.
        Task<ServiceResult<MessageResponse>> StartEnableTwoFactorAsync(Guid userId, string password);

        /// Bật 2 bước - bước 2: nhập đúng mã -> bật.
        Task<ServiceResult<UserDto>> ConfirmEnableTwoFactorAsync(Guid userId, string code);

        /// Tắt 2 bước (nhập lại mật khẩu). Hủy luôn các thiết bị tin cậy.
        Task<ServiceResult<UserDto>> DisableTwoFactorAsync(Guid userId, string password);
        Task<ServiceResult<AuthResponse>> LoginWithGoogleAsync(string idToken);
        Task<ServiceResult<MessageResponse>> ForgotPasswordAsync(ForgotPasswordRequest request);
        Task<ServiceResult<MessageResponse>> ResetPasswordAsync(ResetPasswordRequest request);
    }
}
