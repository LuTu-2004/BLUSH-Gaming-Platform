using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Blush.Api.Controllers
{
    public static class ClaimsPrincipalExtensions
    {
        /// Lấy Id người dùng từ JWT token. Luôn dùng hàm này thay vì tin userId do app gửi lên,
        /// nếu không ai cũng có thể giả làm người khác.
        public static Guid GetUserId(this ClaimsPrincipal user) =>
            Guid.Parse(user.FindFirstValue(JwtRegisteredClaimNames.Sub)!);
    }
}
