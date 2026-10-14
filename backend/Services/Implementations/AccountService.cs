using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Người dùng tự xóa tài khoản
    //   XÓA: hồ sơ, liên kết Google, game/khung giờ/sở thích, nhiệm vụ, huy hiệu, log AI, gói VIP,
    //        mã OTP, thiết bị tin cậy, mọi phòng chat của mình (kèm tin nhắn của cả 2 bên)
    //   GIỮ (ẩn danh, chỉ còn Id): lịch sử thanh toán (kế toán, đối soát cổng) và báo cáo vi phạm (kiểm duyệt)
    // Email đổi thành địa chỉ giả nên email cũ đăng ký lại được; token cũ bị từ chối ngay (Status = Deleted).
    // ============================================================
    public class AccountService : IAccountService
    {
        private readonly BlushDbContext _context;
        private readonly IGoogleTokenValidator _googleValidator;
        private readonly ILogger<AccountService> _logger;

        public AccountService(BlushDbContext context, IGoogleTokenValidator googleValidator, ILogger<AccountService> logger)
        {
            _context = context;
            _googleValidator = googleValidator;
            _logger = logger;
        }

        public async Task<ServiceResult<MessageResponse>> DeleteAsync(Guid userId, DeleteAccountRequest request)
        {
            var user = await _context.Users.Include(u => u.Role).FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null || user.Status == UserStatus.Deleted)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người dùng!");
            }
            // Tài khoản nội bộ: tự xóa có thể làm hệ thống mất người quản trị
            if (user.Role.RoleName != "User")
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Tài khoản Staff/Admin không tự xóa được. Hãy nhờ Admin khác hạ quyền trước.");
            }

            var identityError = await CheckIdentityAsync(user, request);
            if (identityError != null)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, identityError);
            }

            await using var transaction = await _context.Database.BeginTransactionAsync();

            // Phòng chat + tin nhắn (Messages tự xóa theo phòng)
            await _context.ChatRooms.Where(r => r.User1Id == userId || r.User2Id == userId).ExecuteDeleteAsync();

            await _context.UserBlocks.Where(b => b.BlockerId == userId || b.BlockedId == userId).ExecuteDeleteAsync();
            // Feed: tim + bình luận của mình, bài của mình (kèm tim + bình luận của người khác trên bài đó), thành viên Zone
            await _context.PostLikes.Where(l => l.UserId == userId).ExecuteDeleteAsync();
            // Báo cáo trỏ tới bài / bình luận sắp xóa (kể cả bình luận người khác trên bài của mình): giữ báo cáo, bỏ liên kết
            await _context.Reports.Where(r => _context.PostComments.Any(c => c.Id == r.CommentId
                    && (c.AuthorId == userId || _context.Posts.Any(p => p.Id == c.PostId && p.AuthorId == userId))))
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.CommentId, (Guid?)null));
            await _context.Reports.Where(r => _context.Posts.Any(p => p.Id == r.PostId && p.AuthorId == userId))
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.PostId, (Guid?)null));
            await _context.PostComments.Where(c => c.AuthorId == userId).ExecuteDeleteAsync();
            await _context.Posts.Where(p => p.AuthorId == userId).ExecuteDeleteAsync();
            await _context.Posts.Where(p => p.RemovedBy == userId).ExecuteUpdateAsync(s => s.SetProperty(p => p.RemovedBy, (Guid?)null));
            await _context.UserZones.Where(m => m.UserId == userId).ExecuteDeleteAsync();
            await _context.Notifications.Where(n => n.UserId == userId).ExecuteDeleteAsync();
            await _context.Matches.Where(m => m.ReporterId == userId || m.TeammateId == userId).ExecuteDeleteAsync();
            await _context.UserLogins.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.EmailOtps.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.TrustedDevices.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.UserGameProfiles.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.UserHobbies.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.UserPlayTimes.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.UserQuests.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.UserSubscriptions.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.UserProfiles.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.UserBadges.Where(x => x.UserId == userId).ExecuteDeleteAsync();
            await _context.AiLogs.Where(x => x.UserId == userId).ExecuteDeleteAsync();

            var now = DateTime.UtcNow;
            user.Email = $"deleted-{userId:N}@deleted.blush.vn";
            user.EmailConfirmed = false;
            user.PasswordHash = null;
            user.Status = UserStatus.Deleted;
            user.SuspendedUntil = null;
            user.DeletedAt = now;
            user.TwoFactorEnabled = false;
            user.Exp = 0;
            user.Coins = 0;
            user.LastCheckInDate = null;
            user.FailedLoginCount = 0;
            user.LockoutEndAt = null;
            user.UpdatedAt = now;
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation("Tài khoản {UserId} đã tự xóa", userId);
            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Tài khoản và dữ liệu cá nhân của bạn đã được xóa." });
        }

        // Có mật khẩu thì hỏi mật khẩu; chỉ dùng Google thì đăng nhập Google lại (đúng tài khoản Google đã liên kết)
        private async Task<string?> CheckIdentityAsync(User user, DeleteAccountRequest request)
        {
            if (user.PasswordHash != null)
            {
                if (string.IsNullOrEmpty(request.Password)) return "Vui lòng nhập mật khẩu để xác nhận.";
                return BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash) ? null : "Mật khẩu không đúng.";
            }

            if (string.IsNullOrEmpty(request.GoogleIdToken)) return "Vui lòng đăng nhập Google lại để xác nhận.";
            var google = await _googleValidator.ValidateAsync(request.GoogleIdToken);
            var linked = google != null && await _context.UserLogins.AnyAsync(l =>
                l.UserId == user.Id && l.Provider == UserLogin.Google && l.ProviderKey == google.Subject);
            return linked ? null : "Tài khoản Google không khớp với tài khoản BLUSH này.";
        }
    }
}
