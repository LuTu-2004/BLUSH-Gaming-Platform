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
        Task<ServiceResult<AuthResponse>> LoginAsync(LoginRequest request);
        Task<ServiceResult<AuthResponse>> LoginWithGoogleAsync(string idToken);
        Task<ServiceResult<MessageResponse>> ForgotPasswordAsync(ForgotPasswordRequest request);
        Task<ServiceResult<MessageResponse>> ResetPasswordAsync(ResetPasswordRequest request);
    }
}
