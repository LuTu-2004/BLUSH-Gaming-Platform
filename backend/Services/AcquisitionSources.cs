namespace Blush.Api.Services
{
    // Người dùng biết BLUSH qua đâu. Mã PHẢI khớp CHECK của cột UserProfiles.AcquisitionSource
    // (database/migrations/018_acquisition_source.sql) và danh sách trong app (lib/widgets/source_survey.dart).
    public static class AcquisitionSources
    {
        public static readonly IReadOnlyList<(string Code, string Label)> All = new[]
        {
            ("google", "Google"),
            ("facebook", "Facebook"),
            ("tiktok", "TikTok"),
            ("youtube", "YouTube"),
            ("friend", "Bạn bè giới thiệu"),
            ("other", "Khác"),
        };

        public static bool IsValid(string? code) => All.Any(s => s.Code == code);

        public static string LabelOf(string code) => All.FirstOrDefault(s => s.Code == code).Label ?? code;
    }
}
