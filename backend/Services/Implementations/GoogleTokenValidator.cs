using Blush.Api.Options;
using Blush.Api.Services.Interfaces;
using Google.Apis.Auth;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Implementations
{
    // Kiểm tra ID Token bằng thư viện chính thức của Google:
    // chữ ký đúng của Google, chưa hết hạn, và được cấp cho ĐÚNG app của mình (Audience).
    public class GoogleTokenValidator : IGoogleTokenValidator
    {
        private readonly GoogleAuthOptions _options;
        private readonly ILogger<GoogleTokenValidator> _logger;

        public GoogleTokenValidator(IOptions<GoogleAuthOptions> options, ILogger<GoogleTokenValidator> logger)
        {
            _options = options.Value;
            _logger = logger;
        }

        public async Task<GoogleUserInfo?> ValidateAsync(string idToken)
        {
            if (string.IsNullOrWhiteSpace(_options.WebClientId))
            {
                _logger.LogError("Chưa cấu hình GoogleAuth:WebClientId trong appsettings.json");
                return null;
            }

            try
            {
                var payload = await GoogleJsonWebSignature.ValidateAsync(idToken,
                    new GoogleJsonWebSignature.ValidationSettings { Audience = new[] { _options.WebClientId } });

                return new GoogleUserInfo(payload.Subject, payload.Email, payload.EmailVerified, payload.Name, payload.Picture);
            }
            catch (InvalidJwtException ex)
            {
                _logger.LogWarning("Google ID Token không hợp lệ: {Message}", ex.Message);
                return null;
            }
        }
    }
}
