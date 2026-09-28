using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    public interface IAuthService
    {
        Task<ServiceResult<AuthResponse>> RegisterAsync(RegisterRequest request);
        Task<ServiceResult<AuthResponse>> LoginAsync(LoginRequest request);
        Task<ServiceResult<AuthResponse>> LoginWithGoogleAsync(string idToken);
    }
}
