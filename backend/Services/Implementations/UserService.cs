using Blush.Api.DataAccess;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    public class UserService : IUserService
    {
        private readonly BlushDbContext _context;
        private readonly IPlaystyleAnalyzer _playstyle;

        public UserService(BlushDbContext context, IPlaystyleAnalyzer playstyle)
        {
            _context = context;
            _playstyle = playstyle;
        }

        public async Task<UserDto?> GetUserDtoAsync(Guid userId)
        {
            var now = DateTime.UtcNow;

            // Select thẳng ra DTO: EF chỉ lấy đúng các cột cần, không lấy PasswordHash
            return await _context.Users
                .Where(u => u.Id == userId)
                .Select(u => new UserDto
                {
                    Id = u.Id,
                    Email = u.Email,
                    Role = u.Role.RoleName,
                    DisplayName = u.Profile != null ? u.Profile.DisplayName : u.Email,
                    DateOfBirth = u.Profile != null ? u.Profile.DateOfBirth : null,
                    Mbti = u.Profile != null ? u.Profile.Mbti : null,
                    Bio = u.Profile != null ? u.Profile.Bio : null,
                    Region = u.Profile != null ? u.Profile.Region : null,
                    AvatarEmoji = u.Profile != null ? u.Profile.AvatarEmoji : "🎮",
                    AvatarUrl = u.Profile != null ? u.Profile.AvatarUrl : null,
                    SundayAnswer = u.Profile != null ? u.Profile.SundayAnswer : null,
                    OverthinkAnswer = u.Profile != null ? u.Profile.OverthinkAnswer : null,
                    CurrentLevel = u.CurrentLevel,
                    Exp = u.Exp,
                    Coins = u.Coins,
                    VipExpireAt = u.Subscriptions.Where(s => s.EndAt > now).Max(s => (DateTime?)s.EndAt),
                    IsVip = u.Subscriptions.Any(s => s.StartAt <= now && s.EndAt > now),
                    VipPackageName = u.Subscriptions.Where(s => s.EndAt > now).OrderByDescending(s => s.EndAt).Select(s => s.VipPackage.PackageName).FirstOrDefault(),
                    LastCheckInDate = u.LastCheckInDate,
                    HasPassword = u.PasswordHash != null,
                    TwoFactorEnabled = u.TwoFactorEnabled,
                    OnboardingCompleted = u.Profile != null && u.Profile.OnboardingCompletedAt != null,
                })
                .FirstOrDefaultAsync();
        }

        public async Task<ServiceResult<UserDto>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
        {
            var profile = await _context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
            if (profile == null)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy hồ sơ người dùng!");
            }

            profile.Bio = Clean(request.Bio);
            profile.SundayAnswer = Clean(request.SundayAnswer);
            profile.OverthinkAnswer = Clean(request.OverthinkAnswer);
            profile.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            await _playstyle.AnalyzeAsync(userId); // phần giới thiệu đổi -> AI đọc lại phong cách chơi

            return ServiceResult<UserDto>.Ok((await GetUserDtoAsync(userId))!);
        }

        // Ô để trống / toàn dấu cách -> lưu NULL
        private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
