namespace Blush.Api.Services
{
    // Câu hỏi phong cách chơi ở bước 3 khảo sát. Mã PHẢI khớp CHECK của các cột UserProfiles.TeamRole / TalkLevel / BanterLevel
    // (database/migrations/020_playstyle_questions.sql). Không bắt buộc trả lời: null = chưa chọn.
    public static class PlaystyleChoices
    {
        public const string Flex = "Flex";

        // Vai trò trong team
        public static readonly IReadOnlyList<(string Code, string Label)> TeamRoles = new[]
        {
            ("Shotcaller", "Cầm trịch, gọi lệnh"),
            ("Carry", "Gánh team"),
            ("Support", "Hỗ trợ, bọc lót"),
            (Flex, "Linh hoạt, team cần gì chơi nấy"),
        };

        // Mức nói chuyện khi chơi: ít -> nhiều
        public static readonly IReadOnlyList<(string Code, string Label)> TalkLevels = new[]
        {
            ("Quiet", "Ít nói, tập trung chơi"),
            ("Normal", "Nói khi cần (gọi lệnh, báo vị trí)"),
            ("Chatty", "Vừa chơi vừa tám"),
        };

        // Kiểu nói chuyện thấy thoải mái: nhẹ -> mạnh
        public static readonly IReadOnlyList<(string Code, string Label)> BanterLevels = new[]
        {
            ("Gentle", "Nhẹ nhàng, không nói nặng"),
            ("Honest", "Góp ý thẳng nhưng lịch sự"),
            ("Banter", "Cà khịa thoải mái, không để bụng"),
        };

        public static bool IsValid(IReadOnlyList<(string Code, string Label)> list, string? code) => code == null || list.Any(c => c.Code == code);

        public static string LabelOf(IReadOnlyList<(string Code, string Label)> list, string code) => list.FirstOrDefault(c => c.Code == code).Label ?? code;

        // Vị trí trong danh sách có thứ tự (TalkLevels, BanterLevels), -1 = không có
        public static int IndexOf(IReadOnlyList<(string Code, string Label)> list, string? code)
        {
            for (var i = 0; i < list.Count; i++) if (list[i].Code == code) return i;
            return -1;
        }
    }
}
