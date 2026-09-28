using Blush.Api.DataAccess.Entities;

namespace Blush.Api.Services.Interfaces
{
    public interface ITokenService
    {
        /// Tạo JWT access token cho user. Token chứa: Id (sub), email, role.
        (string Token, DateTime ExpiresAt) CreateAccessToken(User user, string roleName);
    }
}
