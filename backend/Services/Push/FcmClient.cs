using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Blush.Api.Options;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Push
{
    public enum FcmResult { Sent, InvalidToken, Failed }

    // Gọi Firebase Cloud Messaging HTTP v1: https://firebase.google.com/docs/cloud-messaging/send-message
    // Đăng nhập bằng file key Service account (Google.Apis.Auth tự lấy và làm mới access token).
    public class FcmClient
    {
        private const string Scope = "https://www.googleapis.com/auth/firebase.messaging";

        // Đọc file key 1 lần cho cả ứng dụng (FcmClient được tạo mới mỗi lần qua HttpClientFactory)
        private static readonly object CredentialLock = new();
        private static (GoogleCredential Credential, string ProjectId)? _cached;

        private readonly HttpClient _http;
        private readonly FirebaseOptions _options;

        public FcmClient(HttpClient http, IOptions<FirebaseOptions> options)
        {
            _http = http;
            _options = options.Value;
        }

        public async Task<FcmResult> SendAsync(string token, PushMessage message, CancellationToken ct)
        {
            var (credential, projectId) = GetCredential();
            var accessToken = await ((ITokenAccess)credential).GetAccessTokenForRequestAsync(cancellationToken: ct);

            var data = new Dictionary<string, string>();
            if (message.Link != null) data["link"] = message.Link;

            var payload = new
            {
                message = new
                {
                    token,
                    notification = new { title = message.Title, body = message.Body },
                    data,
                    android = new
                    {
                        priority = "high",
                        notification = new { tag = message.Tag },
                    },
                },
            };

            using var request = new HttpRequestMessage(HttpMethod.Post, $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send")
            {
                Content = JsonContent.Create(payload, options: new System.Text.Json.JsonSerializerOptions
                {
                    DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
                }),
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            using var response = await _http.SendAsync(request, ct);
            if (response.IsSuccessStatusCode) return FcmResult.Sent;

            // Mã hết hạn / app đã gỡ: 404 UNREGISTERED, hoặc 400 khi mã sai định dạng
            var error = await response.Content.ReadAsStringAsync(ct);
            if (response.StatusCode == HttpStatusCode.NotFound || error.Contains("UNREGISTERED")
                || (response.StatusCode == HttpStatusCode.BadRequest && error.Contains("registration token")))
            {
                return FcmResult.InvalidToken;
            }
            throw new HttpRequestException($"FCM {(int)response.StatusCode}: {error}");
        }

        private (GoogleCredential, string) GetCredential()
        {
            lock (CredentialLock)
            {
                if (_cached == null)
                {
                    var account = CredentialFactory.FromFile<ServiceAccountCredential>(_options.CredentialsPath);
                    _cached = (account.ToGoogleCredential().CreateScoped(Scope), account.ProjectId);
                }
                return _cached.Value;
            }
        }
    }
}
