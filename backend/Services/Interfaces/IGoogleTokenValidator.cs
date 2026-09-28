namespace Blush.Api.Services.Interfaces
{
    public record GoogleUserInfo(string Subject, string Email, bool EmailVerified, string? Name, string? Picture);

    public interface IGoogleTokenValidator
    {
        /// Kiểm tra ID Token do Google cấp. Trả về null nếu token giả / hết hạn / sai app.
        Task<GoogleUserInfo?> ValidateAsync(string idToken);
    }
}
