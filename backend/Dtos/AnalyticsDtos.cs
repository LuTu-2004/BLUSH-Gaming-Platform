namespace Blush.Api.Dtos
{
    // GET api/admin/analytics?days=30 - số liệu Google Analytics cho trang "Google Analytics" của Admin.
    // Landing page = luồng Web, app = luồng Android, cùng 1 GA property (Firebase blush-510011).
    public class AdminAnalyticsDto
    {
        /// false = chưa cấu hình / GA từ chối -> app hiện [Message] hướng dẫn thay cho số liệu
        public bool Available { get; set; }
        public string? Message { get; set; }

        public string? PropertyId { get; set; } // để nút "Mở Google Analytics" mở đúng property
        public int Days { get; set; }
        public DateTime? FetchedAt { get; set; }

        public int RealtimeUsers { get; set; } // đang dùng trong 30 phút qua (web + app)

        // Landing page
        public int WebUsers { get; set; }
        public int WebSessions { get; set; }
        public int WebPageViews { get; set; }
        public int DownloadClicks { get; set; } // sự kiện download_apk
        public List<AnalyticsSourceDto> Sources { get; set; } = new(); // nhiều phiên nhất trước

        // App Android
        public int AppUsers { get; set; }
        public int AppNewUsers { get; set; }
        public List<AnalyticsEventDto> AppEvents { get; set; } = new(); // các sự kiện chính, đủ danh sách (0 nếu chưa có)

        public List<AnalyticsDailyDto> Daily { get; set; } = new(); // đủ mọi ngày trong khoảng
    }

    public class AnalyticsSourceDto
    {
        public string Source { get; set; } = string.Empty; // facebook, google, (direct)...
        public int Sessions { get; set; }
        public int Users { get; set; }
        public int Downloads { get; set; }
    }

    public class AnalyticsEventDto
    {
        public string Name { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class AnalyticsDailyDto
    {
        public DateOnly Date { get; set; }
        public int WebUsers { get; set; }
        public int AppUsers { get; set; }
    }
}
