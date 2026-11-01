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

        // Khu vực = 34 tỉnh/thành sau sáp nhập 07/2025 + "Nước ngoài", mỗi nơi thuộc 1 miền.
        // Giữ mã cũ HCM/HN để không phải đổi dữ liệu đã lưu.
        public const string North = "North", Central = "Central", South = "South", Overseas = "Overseas";

        public static readonly (string Code, string Label)[] Zones =
        {
            (North, "Miền Bắc"), (Central, "Miền Trung"), (South, "Miền Nam"), (Overseas, "Nước ngoài"),
        };

        private static readonly (string Code, string Label, string Zone)[] RegionList =
        {
            ("HN", "Hà Nội", North), ("HP", "Hải Phòng", North), ("QNI", "Quảng Ninh", North), ("BN", "Bắc Ninh", North),
            ("HY", "Hưng Yên", North), ("NB", "Ninh Bình", North), ("PT", "Phú Thọ", North), ("TNG", "Thái Nguyên", North),
            ("TQ", "Tuyên Quang", North), ("LCA", "Lào Cai", North), ("LS", "Lạng Sơn", North), ("CB", "Cao Bằng", North),
            ("SL", "Sơn La", North), ("DB", "Điện Biên", North), ("LCH", "Lai Châu", North),
            ("TH", "Thanh Hóa", Central), ("NA", "Nghệ An", Central), ("HT", "Hà Tĩnh", Central), ("QT", "Quảng Trị", Central),
            ("HUE", "Huế", Central), ("DN", "Đà Nẵng", Central), ("QNG", "Quảng Ngãi", Central), ("GL", "Gia Lai", Central),
            ("DL", "Đắk Lắk", Central), ("KH", "Khánh Hòa", Central), ("LD", "Lâm Đồng", Central),
            ("HCM", "TP. Hồ Chí Minh", South), ("DNA", "Đồng Nai", South), ("TNI", "Tây Ninh", South), ("CT", "Cần Thơ", South),
            ("VL", "Vĩnh Long", South), ("DT", "Đồng Tháp", South), ("AG", "An Giang", South), ("CM", "Cà Mau", South),
            ("OS", "Nước ngoài", Overseas),
        };

        public static readonly string[] Regions = RegionList.Select(r => r.Code).ToArray();

        public static string RegionLabel(string region) =>
            RegionList.FirstOrDefault(r => r.Code == region).Label ?? ZoneLabel(region);

        public static string? ZoneOf(string region) => RegionList.FirstOrDefault(r => r.Code == region).Zone;

        public static string ZoneLabel(string zone) => Zones.FirstOrDefault(z => z.Code == zone).Label ?? zone;

        public static bool IsZone(string code) => Zones.Any(z => z.Code == code);

        // Mã tỉnh -> chính nó; mã miền -> mọi tỉnh trong miền đó
        public static List<string> RegionsIn(string codeOrZone) =>
            IsZone(codeOrZone) ? RegionList.Where(r => r.Zone == codeOrZone).Select(r => r.Code).ToList() : new List<string> { codeOrZone };

        // Rank tự khai: thấp -> cao. MasterFrom = rank "Cao Thủ" hoặc tương đương (nhiệm vụ mùa "Đạt rank Cao Thủ").
        private static readonly Dictionary<string, (string[] Ranks, string MasterFrom)> RanksByGame = new()
        {
            ["Liên Quân Mobile"] = (new[] { "Đồng", "Bạc", "Vàng", "Bạch Kim", "Kim Cương", "Tinh Anh", "Cao Thủ", "Đại Cao Thủ", "Chiến Tướng", "Chiến Thần", "Thách Đấu" }, "Cao Thủ"),
            ["LMHT"] = (new[] { "Sắt", "Đồng", "Bạc", "Vàng", "Bạch Kim", "Lục Bảo", "Kim Cương", "Cao Thủ", "Đại Cao Thủ", "Thách Đấu" }, "Cao Thủ"),
            ["Đấu Trường Chân Lý"] = (new[] { "Sắt", "Đồng", "Bạc", "Vàng", "Bạch Kim", "Lục Bảo", "Kim Cương", "Cao Thủ", "Đại Cao Thủ", "Thách Đấu" }, "Cao Thủ"),
            ["Valorant"] = (new[] { "Sắt", "Đồng", "Bạc", "Vàng", "Bạch Kim", "Kim Cương", "Siêu Việt", "Bất Tử", "Tỏa Sáng" }, "Bất Tử"),
            ["PUBG Mobile"] = (new[] { "Đồng", "Bạc", "Vàng", "Bạch Kim", "Kim Cương", "Vương Miện", "Át", "Chí Tôn" }, "Át"),
            ["Free Fire"] = (new[] { "Đồng", "Bạc", "Vàng", "Bạch Kim", "Kim Cương", "Huyền Thoại", "Thách Đấu" }, "Huyền Thoại"),
        };

        public static List<string> RanksOf(string gameName) =>
            RanksByGame.TryGetValue(gameName, out var r) ? r.Ranks.ToList() : new List<string>();

        public static bool IsMasterOrAbove(string gameName, string rank) =>
            RanksByGame.TryGetValue(gameName, out var r) && Array.IndexOf(r.Ranks, rank) >= Array.IndexOf(r.Ranks, r.MasterFrom);
    }
}
