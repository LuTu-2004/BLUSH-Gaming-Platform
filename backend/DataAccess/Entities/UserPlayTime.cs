namespace Blush.Api.DataAccess.Entities
{
    // Bảng [UserPlayTimes] - khung giờ hay chơi, 1 người nhiều khung
    public class UserPlayTime
    {
        public Guid UserId { get; set; }
        public string Slot { get; set; } = string.Empty; // PlayTimeSlot
    }

    // Giá trị hợp lệ của cột Slot (khớp CHECK trong SQL)
    public static class PlayTimeSlot
    {
        public const string Morning = "Morning";
        public const string Afternoon = "Afternoon";
        public const string Evening = "Evening";
        public const string LateNight = "LateNight";
        public const string Weekend = "Weekend";

        // Nhãn tiếng Việt để app hiển thị
        public static readonly IReadOnlyDictionary<string, string> Labels = new Dictionary<string, string>
        {
            [Morning] = "Sáng (6h - 12h)",
            [Afternoon] = "Chiều (12h - 18h)",
            [Evening] = "Tối (18h - 23h)",
            [LateNight] = "Khuya (23h - 2h)",
            [Weekend] = "Cuối tuần",
        };
    }
}
