using Blush.Api.DataAccess;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services
{
    // Gói VIP đang dùng: Free (chưa mua) / Basic (month_basic) / Pro (month_pro, quarter_pro).
    // Dùng cho hạn mức AI và Zone kín.
    public static class VipTier
    {
        public const string Free = "Free";
        public const string Basic = "Basic";
        public const string Pro = "Pro";

        public static async Task<string> GetAsync(BlushDbContext context, Guid userId)
        {
            var now = DateTime.UtcNow;
            var codes = await context.UserSubscriptions
                .Where(s => s.UserId == userId && s.StartAt <= now && s.EndAt > now)
                .Select(s => s.VipPackage.PackageCode)
                .ToListAsync();
            return codes.Count == 0 ? Free : codes.Any(c => c.Contains("pro")) ? Pro : Basic;
        }
    }
}
