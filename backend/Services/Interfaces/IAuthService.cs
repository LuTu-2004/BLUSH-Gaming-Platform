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

        /// Bật/tắt xác thực 2 bước (phải nhập lại mật khẩu).
        Task<ServiceResult<UserDto>> SetTwoFactorAsync(Guid userId, SetTwoFactorRequest request);
        Task<ServiceResult<AuthResponse>> LoginWithGoogleAsync(string idToken);
        Task<ServiceResult<MessageResponse>> ForgotPasswordAsync(ForgotPasswordRequest request);
        Task<ServiceResult<MessageResponse>> ResetPasswordAsync(ResetPasswordRequest request);
    }
}
