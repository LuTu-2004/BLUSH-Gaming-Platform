using Blush.Api.DataAccess.Entities;

namespace Blush.Api.Services
{
    // Nhãn tiếng Việt + vị trí gợi ý cho từng game, dùng chung cho onboarding và ghép đội.
    // Bảng Games chưa có cột vị trí nên tạm để ở đây; game mới Admin thêm sẽ không có gợi ý (người dùng bỏ trống vị trí).
    public static class GameCatalog
    {
        private static readonly Dictionary<string, string[]> PositionsByGame = new()
        {
            ["Liên Quân Mobile"] = new[] { "Đường Caesar", "Đi rừng", "Đường giữa", "Xạ thủ", "Trợ thủ" },
            ["LMHT"] = new[] { "Đường trên", "Đi rừng", "Đường giữa", "Xạ thủ", "Hỗ trợ" },
            ["Valorant"] = new[] { "Duelist", "Initiator", "Controller", "Sentinel" },
            ["PUBG Mobile"] = new[] { "Tiên phong", "Xạ thủ", "Hỗ trợ", "Lái xe" },
            ["Free Fire"] = new[] { "Tiên phong", "Xạ thủ", "Hỗ trợ", "Bắn tỉa" },
        };

        public static List<string> PositionsOf(string gameName) =>
            PositionsByGame.TryGetValue(gameName, out var positions) ? positions.ToList() : new List<string>();

        public static string PurposeLabel(string purpose) => purpose switch
        {
            GamePurpose.Tryhard => "Leo rank nghiêm túc",
            GamePurpose.Fun => "Chơi vui, giải trí",
            GamePurpose.Event => "Săn sự kiện",
            _ => purpose,
        };

        public static string RegionLabel(string region) => region switch
        {
            "HCM" => "TP. Hồ Chí Minh",
            "HN" => "Hà Nội",
            _ => region,
        };

        public static readonly string[] Regions = { "HCM", "HN" };
    }
}
