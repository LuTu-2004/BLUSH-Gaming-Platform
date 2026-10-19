using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Blush.Api.Options;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Analytics
{
    /// GA từ chối / cấu hình sai: [Message] là lời nhắn cho Admin (tiếng Việt, kèm cách sửa)
    public class GaDataException : Exception
    {
        public GaDataException(string message) : base(message) { }
    }

    /// 1 báo cáo GA rút gọn: mỗi dòng = giá trị các dimension + giá trị các metric (số nguyên)
    public record GaRow(string[] Dimensions, long[] Metrics);

    // Gọi Google Analytics Data API v1beta: https://developers.google.com/analytics/devguides/reporting/data/v1
    // Đăng nhập bằng file key Service account của Firebase (giống FcmClient), quyền chỉ đọc.
    public class GaDataClient
    {
        private const string Scope = "https://www.googleapis.com/auth/analytics.readonly";
        private const string BaseUrl = "https://analyticsdata.googleapis.com/v1beta/properties/";

        private static readonly object CredentialLock = new();
        private static (GoogleCredential Credential, string Email)? _cached;

        private readonly HttpClient _http;
        private readonly FirebaseOptions _firebase;
        private readonly GoogleAnalyticsOptions _options;

        public GaDataClient(HttpClient http, IOptions<FirebaseOptions> firebase, IOptions<GoogleAnalyticsOptions> options)
        {
            _http = http;
            _firebase = firebase.Value;
            _options = options.Value;
        }

        /// Chạy tối đa 5 báo cáo trong 1 lần gọi (giới hạn của GA). [requests]: object theo mẫu RunReportRequest.
        public async Task<List<List<GaRow>>> BatchRunReportsAsync(IEnumerable<object> requests, CancellationToken ct)
        {
            var json = await PostAsync(":batchRunReports", new { requests }, ct);
            return json.GetProperty("reports").EnumerateArray().Select(ReadRows).ToList();
        }

        /// Số người đang dùng trong 30 phút qua
        public async Task<long> RealtimeActiveUsersAsync(CancellationToken ct)
        {
            var json = await PostAsync(":runRealtimeReport", new { metrics = new[] { new { name = "activeUsers" } } }, ct);
            return ReadRows(json).Sum(r => r.Metrics[0]);
        }

        private async Task<JsonElement> PostAsync(string action, object body, CancellationToken ct)
        {
            if (!_options.IsConfigured) throw new GaDataException("Chưa đặt GoogleAnalytics:PropertyId trong appsettings.json (dãy số trong GA → Admin → Property details).");
            if (!_firebase.IsConfigured) throw new GaDataException("Chưa đặt Firebase:CredentialsPath (file key Service account) nên chưa đăng nhập được Google Analytics.");

            var (credential, email) = GetCredential();
            var accessToken = await ((ITokenAccess)credential).GetAccessTokenForRequestAsync(cancellationToken: ct);
            using var request = new HttpRequestMessage(HttpMethod.Post, BaseUrl + _options.PropertyId.Trim() + action) { Content = JsonContent.Create(body) };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            using var response = await _http.SendAsync(request, ct);
            var text = await response.Content.ReadAsStringAsync(ct);
            return response.StatusCode switch
            {
                HttpStatusCode.OK => JsonDocument.Parse(text).RootElement.Clone(),
                // Project Google Cloud của file key chưa bật API (cũng trả 403 nhưng khác lỗi thiếu quyền)
                HttpStatusCode.Forbidden when text.Contains("SERVICE_DISABLED") || text.Contains("has not been used") => throw new GaDataException(
                    "Chưa bật Google Analytics Data API cho project Firebase. Mở https://console.cloud.google.com/apis/library/analyticsdata.googleapis.com?project="
                    + ProjectIdOf(email) + " → Enable, đợi 1-2 phút rồi bấm Làm mới."),
                HttpStatusCode.Forbidden or HttpStatusCode.Unauthorized => throw new GaDataException(
                    $"Service account chưa có quyền xem Google Analytics. Vào GA → Admin → Property access management, thêm {email} với vai trò Viewer."),
                HttpStatusCode.NotFound or HttpStatusCode.BadRequest when text.Contains("property", StringComparison.OrdinalIgnoreCase) => throw new GaDataException(
                    $"Không tìm thấy GA property {_options.PropertyId}. Kiểm tra lại Property ID (dãy số, không phải mã G-...)."),
                _ => throw new HttpRequestException($"GA Data API {(int)response.StatusCode}: {text}"),
            };
        }

        /// "x@blush-510011.iam.gserviceaccount.com" -> "blush-510011"
        private static string ProjectIdOf(string serviceAccountEmail) =>
            serviceAccountEmail.Split('@').ElementAtOrDefault(1)?.Split('.').FirstOrDefault() ?? string.Empty;

        private static List<GaRow> ReadRows(JsonElement report)
        {
            if (!report.TryGetProperty("rows", out var rows)) return new(); // không có dữ liệu -> GA bỏ hẳn "rows"
            return rows.EnumerateArray().Select(r => new GaRow(
                r.TryGetProperty("dimensionValues", out var d) ? d.EnumerateArray().Select(v => v.GetProperty("value").GetString() ?? string.Empty).ToArray() : Array.Empty<string>(),
                r.GetProperty("metricValues").EnumerateArray().Select(v => long.TryParse(v.GetProperty("value").GetString(), out var n) ? n : 0).ToArray()
            )).ToList();
        }

        private (GoogleCredential, string) GetCredential()
        {
            lock (CredentialLock)
            {
                if (_cached == null)
                {
                    var account = CredentialFactory.FromFile<ServiceAccountCredential>(_firebase.CredentialsPath);
                    _cached = (account.ToGoogleCredential().CreateScoped(Scope), account.Id);
                }
                return _cached.Value;
            }
        }
    }
}
