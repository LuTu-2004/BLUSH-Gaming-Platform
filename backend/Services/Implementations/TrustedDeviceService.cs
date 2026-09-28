using System.Security.Cryptography;
using System.Text;
using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - "Tin cậy thiết bị này 30 ngày" (bỏ qua mã 2 bước)
    // ============================================================
    public class TrustedDeviceService : ITrustedDeviceService
    {
        private static readonly TimeSpan TrustDuration = TimeSpan.FromDays(30);

        private readonly BlushDbContext _context;

        public TrustedDeviceService(BlushDbContext context)
        {
            _context = context;
        }

        public async Task<string> CreateAsync(Guid userId, string? deviceName)
        {
            // 32 byte ngẫu nhiên an toàn -> chuỗi base64url (không đoán được)
            var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
                .Replace('+', '-').Replace('/', '_').TrimEnd('=');
            var now = DateTime.UtcNow;

            _context.TrustedDevices.Add(new TrustedDevice
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                TokenHash = Hash(token),
                DeviceName = deviceName?.Length > 100 ? deviceName[..100] : deviceName,
                ExpiresAt = now.Add(TrustDuration),
                CreatedAt = now,
            });
            await _context.SaveChangesAsync();
            return token;
        }

        public async Task<bool> IsTrustedAsync(Guid userId, string? deviceToken)
        {
            if (string.IsNullOrWhiteSpace(deviceToken)) return false;

            var hash = Hash(deviceToken);
            var now = DateTime.UtcNow;
            var device = await _context.TrustedDevices
                .FirstOrDefaultAsync(d => d.UserId == userId && d.TokenHash == hash && d.ExpiresAt > now);
            if (device == null) return false;

            device.LastUsedAt = now;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task RevokeAllAsync(Guid userId)
        {
            var devices = await _context.TrustedDevices.Where(d => d.UserId == userId).ToListAsync();
            _context.TrustedDevices.RemoveRange(devices);
            await _context.SaveChangesAsync();
        }

        private static string Hash(string token) =>
            Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    }
}
