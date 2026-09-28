namespace Blush.Api.Services
{
    // DB lưu giờ UTC, nhưng "một ngày" (điểm danh, nhiệm vụ hằng ngày) phải tính theo giờ Việt Nam (UTC+7)
    public static class VietnamTime
    {
        public static DateOnly Today => DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
    }
}
