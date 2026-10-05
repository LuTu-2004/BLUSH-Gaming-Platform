namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Games] - danh sách game do Admin quản lý
    public class Game
    {
        public int Id { get; set; }
        public string GameName { get; set; } = string.Empty;
        public string? Genre { get; set; }
        public string? IconUrl { get; set; }
        public bool IsActive { get; set; } = true;
    }

    // Giá trị hợp lệ của cột Purpose (khớp CHECK trong SQL)
    public static class GamePurpose
    {
        public const string Tryhard = "Tryhard";
        public const string Fun = "Fun";
        public const string Event = "Event";

        public static readonly string[] All = { Tryhard, Fun, Event };
    }
}
