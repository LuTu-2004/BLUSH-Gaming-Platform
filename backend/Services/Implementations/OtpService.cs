using System.Security.Cryptography;
using System.Text;
using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Mã OTP 6 số qua email
    // ============================================================
    public class OtpService : IOtpService
    {
        private static readonly TimeSpan CodeLifetime = TimeSpan.FromMinutes(10);
        private static readonly TimeSpan ResendCooldown = TimeSpan.FromSeconds(60);
        private const int MaxAttempts = 5;

        private readonly BlushDbContext _context;
        private readonly IEmailSender _emailSender;

        public OtpService(BlushDbContext context, IEmailSender emailSender)
        {
            _context = context;
            _emailSender = emailSender;
        }

        public async Task<ServiceResult<bool>> SendAsync(User user, string purpose)
        {
            var now = DateTime.UtcNow;

            // Chống spam: mỗi 60 giây chỉ được gửi 1 mã
            var lastSentAt = await _context.EmailOtps
                .Where(o => o.UserId == user.Id && o.Purpose == purpose)
                .MaxAsync(o => (DateTime?)o.CreatedAt);
            if (lastSentAt != null && now - lastSentAt < ResendCooldown)
            {
                var wait = (int)Math.Ceiling((ResendCooldown - (now - lastSentAt.Value)).TotalSeconds);
                return ServiceResult<bool>.Fail(StatusCodes.Status429TooManyRequests, $"Vui lòng đợi {wait} giây rồi gửi lại mã.");
            }

            // Mã cũ chưa dùng -> hủy, chỉ mã mới nhất có hiệu lực
            var oldCodes = await _context.EmailOtps
                .Where(o => o.UserId == user.Id && o.Purpose == purpose && o.ConsumedAt == null)
                .ToListAsync();
            oldCodes.ForEach(o => o.ConsumedAt = now);

            // RandomNumberGenerator: sinh số ngẫu nhiên an toàn (không dùng new Random() vì đoán được)
            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            _context.EmailOtps.Add(new EmailOtp
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Purpose = purpose,
                CodeHash = Hash(user.Id, purpose, code),
                ExpiresAt = now.Add(CodeLifetime),
                CreatedAt = now,
            });
            await _context.SaveChangesAsync();

            var (subject, title) = purpose switch
            {
                OtpPurpose.VerifyEmail => ("Mã xác minh tài khoản BLUSH", "Xác minh email của bạn"),
                OtpPurpose.TwoFactorLogin => ("Mã đăng nhập BLUSH", "Có người đang đăng nhập tài khoản của bạn"),
                _ => ("Mã đặt lại mật khẩu BLUSH", "Đặt lại mật khẩu"),
            };
            await _emailSender.SendAsync(user.Email, subject, BuildEmailHtml(title, code));

            return ServiceResult<bool>.Ok(true);
        }

        public async Task<ServiceResult<bool>> VerifyAsync(Guid userId, string purpose, string code)
        {
            var now = DateTime.UtcNow;
            var otp = await _context.EmailOtps
                .Where(o => o.UserId == userId && o.Purpose == purpose && o.ConsumedAt == null)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();

            if (otp == null || otp.ExpiresAt <= now || otp.Attempts >= MaxAttempts)
            {
                return ServiceResult<bool>.Fail(StatusCodes.Status400BadRequest, "Mã đã hết hạn. Vui lòng bấm \"Gửi lại mã\".");
            }

            if (otp.CodeHash != Hash(userId, purpose, code.Trim()))
            {
                otp.Attempts++;
                await _context.SaveChangesAsync();
                int left = MaxAttempts - otp.Attempts;
                return ServiceResult<bool>.Fail(StatusCodes.Status400BadRequest,
                    left > 0 ? $"Mã không đúng. Bạn còn {left} lần thử." : "Nhập sai quá nhiều lần. Vui lòng bấm \"Gửi lại mã\".");
            }

            otp.ConsumedAt = now;
            await _context.SaveChangesAsync();
            return ServiceResult<bool>.Ok(true);
        }

        // Chỉ lưu bản băm: lỡ lộ database cũng không đọc được mã đang có hiệu lực
        private static string Hash(Guid userId, string purpose, string code) =>
            Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes($"{userId}:{purpose}:{code}")));

        private static string BuildEmailHtml(string title, string code) => $"""
            <div style="font-family:Segoe UI,Roboto,sans-serif;max-width:480px;margin:auto;padding:24px;border-radius:16px;background:#13131b;color:#e4e1ed">
              <h2 style="color:#d2bbff;margin-top:0">{title}</h2>
              <p>Mã của bạn là:</p>
              <p style="font-size:32px;font-weight:800;letter-spacing:8px;color:#fff;background:#7c3aed;border-radius:12px;padding:12px;text-align:center">{code}</p>
              <p>Mã có hiệu lực trong 10 phút. Không chia sẻ mã này cho bất kỳ ai, kể cả người tự xưng là nhân viên BLUSH.</p>
              <p style="color:#a9a3b8;font-size:13px">Nếu bạn không yêu cầu mã này, hãy bỏ qua email. Nếu đây là mã đăng nhập mà bạn không hề đăng nhập, hãy đổi mật khẩu ngay.</p>
            </div>
            """;
    }
}
