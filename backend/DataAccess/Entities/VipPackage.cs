namespace Blush.Api.DataAccess.Entities
{
    // Bảng [VipPackages] - 'month_basic' (29K) và 'month_pro' (49K)
    public class VipPackage
    {
        public int Id { get; set; }
        public string PackageCode { get; set; } = string.Empty;
        public string PackageName { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int DurationDays { get; set; }
        public int AiTokenLimit { get; set; }
        public string? Description { get; set; }
        public string? Badge { get; set; }
        public bool IsActive { get; set; }
    }
}
