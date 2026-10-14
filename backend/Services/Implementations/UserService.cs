using Blush.Api.DataAccess;
using Blush.Api.Dtos;
using Blush.Api.Options;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;

namespace Blush.Api.Services.Implementations
{
    public class UserService : IUserService
    {
        public const int AvatarSize = 512;
        private const long MaxAvatarPixels = 40_000_000; // ảnh điện thoại ~12-50MP; lớn hơn nữa là ảnh "bom" làm tràn RAM

        private readonly BlushDbContext _context;
        private readonly IPlaystyleAnalyzer _playstyle;
        private readonly IFileStorage _storage;
        private readonly StorageOptions _storageOptions;

        public UserService(BlushDbContext context, IPlaystyleAnalyzer playstyle, IFileStorage storage, IOptions<StorageOptions> storageOptions)
        {
            _context = context;
            _playstyle = playstyle;
            _storage = storage;
            _storageOptions = storageOptions.Value;
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

        public async Task<ServiceResult<UserDto>> UpdateAvatarAsync(Guid userId, Stream image, long length, CancellationToken ct = default)
        {
            if (length == 0) return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, "Chưa chọn ảnh.");
            if (length > _storageOptions.MaxAvatarBytes)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, $"Ảnh tối đa {_storageOptions.MaxAvatarBytes / 1024 / 1024}MB.");
            }
            var profile = await _context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userId, ct);
            if (profile == null) return ServiceResult<UserDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy hồ sơ người dùng!");

            // Không tin đuôi file / Content-Type app gửi: đọc thử nội dung rồi vẽ lại thành JPEG mới.
            // Vẽ lại = bỏ hết thông tin kèm theo ảnh (vị trí GPS, máy chụp) và mọi thứ không phải điểm ảnh.
            using var output = new MemoryStream();
            try
            {
                using var buffer = new MemoryStream();
                await image.CopyToAsync(buffer, ct);
                buffer.Position = 0;
                var info = await Image.IdentifyAsync(buffer, ct);
                if ((long)info.Width * info.Height > MaxAvatarPixels)
                {
                    return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, "Ảnh quá lớn, hãy chọn ảnh khác.");
                }
                buffer.Position = 0;
                using var img = await Image.LoadAsync(new DecoderOptions { TargetSize = new Size(AvatarSize * 2) }, buffer, ct);
                img.Mutate(x => x
                    .AutoOrient() // ảnh chụp dọc trên điện thoại không bị xoay ngang
                    .Resize(new ResizeOptions { Size = new Size(AvatarSize), Mode = ResizeMode.Crop })
                    .BackgroundColor(Color.White)); // PNG trong suốt -> nền trắng (JPEG không có trong suốt)
                img.Metadata.ExifProfile = null;
                img.Metadata.IptcProfile = null;
                img.Metadata.XmpProfile = null;
                await img.SaveAsJpegAsync(output, new JpegEncoder { Quality = 85 }, ct);
            }
            catch (ImageFormatException)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, "File không phải ảnh hoặc ảnh bị lỗi (dùng JPG, PNG hoặc WebP).");
            }

            // Tên file mới mỗi lần đổi -> app không hiện ảnh cũ còn trong bộ nhớ đệm
            output.Position = 0;
            var url = await _storage.SaveAsync("avatars", $"{userId:N}-{Guid.NewGuid():N}.jpg", output, ct);
            var oldUrl = profile.AvatarUrl;
            profile.AvatarUrl = url;
            profile.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(ct);
            await _storage.DeleteAsync(oldUrl);

            return ServiceResult<UserDto>.Ok((await GetUserDtoAsync(userId))!);
        }

        public async Task<ServiceResult<UserDto>> RemoveAvatarAsync(Guid userId)
        {
            var profile = await _context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
            if (profile == null) return ServiceResult<UserDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy hồ sơ người dùng!");

            var oldUrl = profile.AvatarUrl;
            profile.AvatarUrl = null;
            profile.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            await _storage.DeleteAsync(oldUrl);

            return ServiceResult<UserDto>.Ok((await GetUserDtoAsync(userId))!);
        }

        // Ô để trống / toàn dấu cách -> lưu NULL
        private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
