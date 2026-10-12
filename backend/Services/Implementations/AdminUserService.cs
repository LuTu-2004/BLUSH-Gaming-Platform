using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Admin quản lý người dùng: danh sách, khóa / mở khóa, đổi vai trò
    // Khóa hoặc đổi vai trò có hiệu lực ngay: mỗi request đều kiểm tra lại trong DB
    // (xem OnTokenValidated trong Program.cs), token cũ bị từ chối.
    // ============================================================
    public class AdminUserService : IAdminUserService
    {
        private readonly BlushDbContext _context;

        public AdminUserService(BlushDbContext context)
        {
            _context = context;
        }

        public async Task<AdminUserListDto> GetUsersAsync(string? search, string? role, string? status, int page, int pageSize)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var now = DateTime.UtcNow;

            var query = _context.Users.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search))
            {
                var keyword = search.Trim();
                query = query.Where(u => u.Email.Contains(keyword) || (u.Profile != null && u.Profile.DisplayName.Contains(keyword)));
            }
            if (!string.IsNullOrWhiteSpace(role)) query = query.Where(u => u.Role.RoleName == role);
            // Tạm khóa đã hết hạn thì coi như đang hoạt động (DB chỉ tự mở lại ở lần đăng nhập kế tiếp)
            query = status switch
            {
                UserStatus.Active => query.Where(u => u.Status == UserStatus.Active || (u.Status == UserStatus.Suspended && !(u.SuspendedUntil > now))),
                UserStatus.Suspended => query.Where(u => u.Status == UserStatus.Suspended && u.SuspendedUntil > now),
                UserStatus.Banned => query.Where(u => u.Status == UserStatus.Banned),
                _ => query,
            };

            var total = await query.CountAsync();
            var items = await ToDto(query.OrderByDescending(u => u.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize), now).ToListAsync();

            var stats = new AdminUserStatsDto
            {
                Total = await _context.Users.CountAsync(),
                Vip = await _context.Users.CountAsync(u => u.Subscriptions.Any(s => s.StartAt <= now && s.EndAt > now)),
                Locked = await _context.Users.CountAsync(u => u.Status == UserStatus.Banned || (u.Status == UserStatus.Suspended && u.SuspendedUntil > now)),
            };

            return new AdminUserListDto { Items = items, Total = total, Page = page, PageSize = pageSize, Stats = stats };
        }

        public async Task<ServiceResult<AdminUserDto>> UpdateStatusAsync(Guid adminId, Guid userId, UpdateUserStatusRequest request)
        {
            if (adminId == userId)
            {
                return ServiceResult<AdminUserDto>.Fail(StatusCodes.Status400BadRequest, "Bạn không thể tự khóa tài khoản của mình.");
            }
            if (request.Status == UserStatus.Suspended && request.SuspendDays == null)
            {
                return ServiceResult<AdminUserDto>.Fail(StatusCodes.Status400BadRequest, "Vui lòng chọn số ngày tạm khóa.");
            }
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return ServiceResult<AdminUserDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người dùng!");
            }

            var now = DateTime.UtcNow;
            user.Status = request.Status;
            user.SuspendedUntil = request.Status == UserStatus.Suspended ? now.AddDays(request.SuspendDays!.Value) : null;
            user.UpdatedAt = now;
            await _context.SaveChangesAsync();

            return ServiceResult<AdminUserDto>.Ok(await GetDtoAsync(userId));
        }

        public async Task<ServiceResult<AdminUserDto>> UpdateRoleAsync(Guid adminId, Guid userId, UpdateUserRoleRequest request)
        {
            // Tự đổi thì có thể tự mất quyền Admin. Vì luôn có 1 Admin khác làm thao tác này nên hệ thống không bao giờ hết Admin.
            if (adminId == userId)
            {
                return ServiceResult<AdminUserDto>.Fail(StatusCodes.Status400BadRequest, "Bạn không thể tự đổi vai trò của mình.");
            }
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return ServiceResult<AdminUserDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người dùng!");
            }

            var role = await _context.Roles.FirstAsync(r => r.RoleName == request.Role);
            user.RoleId = role.Id;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return ServiceResult<AdminUserDto>.Ok(await GetDtoAsync(userId));
        }

        private async Task<AdminUserDto> GetDtoAsync(Guid userId) =>
            await ToDto(_context.Users.AsNoTracking().Where(u => u.Id == userId), DateTime.UtcNow).FirstAsync();

        private static IQueryable<AdminUserDto> ToDto(IQueryable<User> users, DateTime now) =>
            users.Select(u => new AdminUserDto
            {
                Id = u.Id,
                Email = u.Email,
                DisplayName = u.Profile != null ? u.Profile.DisplayName : u.Email,
                AvatarUrl = u.Profile != null ? u.Profile.AvatarUrl : null,
                Role = u.Role.RoleName,
                Status = u.Status == UserStatus.Suspended && !(u.SuspendedUntil > now) ? UserStatus.Active : u.Status,
                SuspendedUntil = u.Status == UserStatus.Suspended && u.SuspendedUntil > now ? u.SuspendedUntil : null,
                IsVip = u.Subscriptions.Any(s => s.StartAt <= now && s.EndAt > now),
                Level = u.CurrentLevel,
                Exp = u.Exp,
                CreatedAt = u.CreatedAt,
                LastLoginAt = u.LastLoginAt,
            });
    }
}
