using System.Globalization;
using Blush.Api.Dtos;
using Blush.Api.Options;
using Blush.Api.Services.Analytics;
using Blush.Api.Services.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Số liệu Google Analytics cho Admin
    // Landing page (frontend/landing, luồng Web) gửi page_view + download_apk kèm nguồn utm_source.
    // App Android (lib/services/analytics.dart) gửi sign_up, start_chat, purchase...
    // Cả 2 cùng 1 GA property -> tách bằng dimension "platform" (web / Android).
    // ============================================================
    public class AdminAnalyticsService : IAdminAnalyticsService
    {
        // Sự kiện chính của app, theo thứ tự hành trình người dùng. first_open do Firebase tự ghi.
        private static readonly (string Name, string Label)[] AppEvents =
        {
            ("first_open", "Mở app lần đầu"),
            ("sign_up", "Đăng ký"),
            ("login", "Đăng nhập"),
            ("survey_saved", "Lưu khảo sát ghép đội"),
            ("start_chat", "Bắt chuyện"),
            ("answer_icebreaker", "Trả lời câu hỏi phá băng"),
            ("begin_checkout", "Bắt đầu mua VIP"),
            ("purchase", "Mua VIP thành công"),
            ("rate_app", "Đánh giá app"),
        };

        private readonly GaDataClient _ga;
        private readonly IMemoryCache _cache;
        private readonly GoogleAnalyticsOptions _options;
        private readonly ILogger<AdminAnalyticsService> _logger;

        public AdminAnalyticsService(GaDataClient ga, IMemoryCache cache, IOptions<GoogleAnalyticsOptions> options, ILogger<AdminAnalyticsService> logger)
        {
            _ga = ga;
            _cache = cache;
            _options = options.Value;
            _logger = logger;
        }

        public async Task<AdminAnalyticsDto> GetAsync(int days, CancellationToken ct = default)
        {
            days = days is 7 or 30 or 90 ? days : 30;
            var cacheKey = $"admin-analytics-{days}";
            if (_cache.TryGetValue(cacheKey, out AdminAnalyticsDto? cached) && cached != null) return cached;

            AdminAnalyticsDto result;
            try
            {
                result = await FetchAsync(days, ct);
            }
            catch (GaDataException e)
            {
                // Lỗi cấu hình: báo Admin cách sửa, không lưu cache để sửa xong là thấy ngay
                return new AdminAnalyticsDto { Available = false, Message = e.Message, Days = days, PropertyId = NullIfEmpty(_options.PropertyId) };
            }
            catch (Exception e) when (e is HttpRequestException or TaskCanceledException)
            {
                _logger.LogWarning(e, "Không lấy được số liệu Google Analytics");
                return new AdminAnalyticsDto { Available = false, Message = "Không kết nối được Google Analytics, thử lại sau ít phút.", Days = days, PropertyId = NullIfEmpty(_options.PropertyId) };
            }

            _cache.Set(cacheKey, result, TimeSpan.FromMinutes(Math.Max(1, _options.CacheMinutes)));
            return result;
        }

        private async Task<AdminAnalyticsDto> FetchAsync(int days, CancellationToken ct)
        {
            var range = new[] { new { startDate = $"{days - 1}daysAgo", endDate = "today" } };
            var web = Is("platform", "web");
            var android = Is("platform", "Android");

            var reports = await _ga.BatchRunReportsAsync(new object[]
            {
                // 0. Tổng theo nền tảng
                new
                {
                    dateRanges = range,
                    dimensions = Dims("platform"),
                    metrics = Metrics("activeUsers", "newUsers", "sessions", "screenPageViews"),
                },
                // 1. Landing: phiên + người theo nguồn
                new
                {
                    dateRanges = range,
                    dimensions = Dims("sessionSource"),
                    metrics = Metrics("sessions", "activeUsers"),
                    dimensionFilter = web,
                    orderBys = new[] { new { metric = new { metricName = "sessions" }, desc = true } },
                    limit = 10,
                },
                // 2. Landing: lượt bấm tải APK theo nguồn
                new
                {
                    dateRanges = range,
                    dimensions = Dims("sessionSource"),
                    metrics = Metrics("eventCount"),
                    dimensionFilter = And(web, Is("eventName", "download_apk")),
                },
                // 3. App: số lần mỗi sự kiện chính
                new
                {
                    dateRanges = range,
                    dimensions = Dims("eventName"),
                    metrics = Metrics("eventCount"),
                    dimensionFilter = And(android, new { filter = new { fieldName = "eventName", inListFilter = new { values = AppEvents.Select(e => e.Name).ToArray() } } }),
                },
                // 4. Người dùng mỗi ngày theo nền tảng
                new
                {
                    dateRanges = range,
                    dimensions = Dims("date", "platform"),
                    metrics = Metrics("activeUsers"),
                },
            }, ct);
            var realtime = await _ga.RealtimeActiveUsersAsync(ct);

            var byPlatform = reports[0];
            long Sum(string platform, int metric) =>
                byPlatform.Where(r => string.Equals(r.Dimensions[0], platform, StringComparison.OrdinalIgnoreCase)).Sum(r => r.Metrics[metric]);

            var downloads = reports[2].ToDictionary(r => r.Dimensions[0], r => r.Metrics[0]);
            var events = reports[3].ToDictionary(r => r.Dimensions[0], r => r.Metrics[0]);

            var daily = reports[4]
                .GroupBy(r => r.Dimensions[0])
                .ToDictionary(g => g.Key, g => (
                    Web: g.Where(r => r.Dimensions[1].Equals("web", StringComparison.OrdinalIgnoreCase)).Sum(r => r.Metrics[0]),
                    App: g.Where(r => r.Dimensions[1].Equals("Android", StringComparison.OrdinalIgnoreCase)).Sum(r => r.Metrics[0])));
            var today = VietnamTime.Today;

            return new AdminAnalyticsDto
            {
                Available = true,
                PropertyId = _options.PropertyId.Trim(),
                Days = days,
                FetchedAt = DateTime.UtcNow,
                RealtimeUsers = (int)realtime,
                WebUsers = (int)Sum("web", 0),
                WebSessions = (int)Sum("web", 2),
                WebPageViews = (int)Sum("web", 3),
                DownloadClicks = (int)downloads.Values.Sum(),
                Sources = reports[1]
                    .Select(r => new AnalyticsSourceDto
                    {
                        Source = r.Dimensions[0],
                        Sessions = (int)r.Metrics[0],
                        Users = (int)r.Metrics[1],
                        Downloads = (int)downloads.GetValueOrDefault(r.Dimensions[0]),
                    })
                    .ToList(),
                AppUsers = (int)Sum("Android", 0),
                AppNewUsers = (int)Sum("Android", 1),
                AppEvents = AppEvents.Select(e => new AnalyticsEventDto { Name = e.Name, Label = e.Label, Count = (int)events.GetValueOrDefault(e.Name) }).ToList(),
                // Đủ mọi ngày (ngày không có ai = 0) để biểu đồ không hụt cột
                Daily = Enumerable.Range(0, days)
                    .Select(i => today.AddDays(i - days + 1))
                    .Select(d =>
                    {
                        var (webUsers, appUsers) = daily.GetValueOrDefault(d.ToString("yyyyMMdd", CultureInfo.InvariantCulture));
                        return new AnalyticsDailyDto { Date = d, WebUsers = (int)webUsers, AppUsers = (int)appUsers };
                    })
                    .ToList(),
            };
        }

        private static object[] Dims(params string[] names) => names.Select(n => (object)new { name = n }).ToArray();

        private static object[] Metrics(params string[] names) => names.Select(n => (object)new { name = n }).ToArray();

        private static object Is(string field, string value) =>
            new { filter = new { fieldName = field, stringFilter = new { value, matchType = "EXACT", caseSensitive = false } } };

        private static object And(params object[] expressions) => new { andGroup = new { expressions } };

        private static string? NullIfEmpty(string value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
