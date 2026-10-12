namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Badges] - huy hiệu. Description = điều kiện nhận, luật kiểm tra nằm ở BadgeService (theo Code).
    public class Badge
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string NameVI { get; set; } = string.Empty;
        public string? NameEN { get; set; }
        public string Icon { get; set; } = string.Empty;
        public string? Description { get; set; }
    }

    // Bảng [UserBadges] - huy hiệu đã nhận
    public class UserBadge
    {
        public Guid UserId { get; set; }
        public int BadgeId { get; set; }
        public DateTime EarnedAt { get; set; }
    }

    public static class BadgeCode
    {
        public const string Top1Fun = "top1_fun";
        public const string LocalMvp = "local_mvp";
        public const string TryhardKing = "tryhard_king";
        public const string FirstConnection = "first_connection";
        public const string ZoneStar = "zone_star";
        public const string Friendly = "friendly";
        public const string HardWorker = "hard_worker";
        public const string Supporter = "supporter";
    }
}
