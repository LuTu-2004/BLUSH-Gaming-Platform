using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Khảo sát sau đăng ký
    // Lưu vào: UserGameProfiles (game), UserPlayTimes (khung giờ), UserHobbies (sở thích),
    //          UserProfiles (khu vực, mic, mô tả đồng đội, thời điểm hoàn tất)
    // ============================================================
    public class OnboardingService : IOnboardingService
    {
        private readonly BlushDbContext _context;
        private readonly IUserService _userService;

        public OnboardingService(BlushDbContext context, IUserService userService)
        {
            _context = context;
            _userService = userService;
        }

        public async Task<OnboardingOptionsDto> GetOptionsAsync()
        {
            var games = await _context.Games.Where(g => g.IsActive).OrderBy(g => g.Id).ToListAsync();
            var hobbies = await _context.Hobbies.OrderBy(h => h.Id).ToListAsync();

            return new OnboardingOptionsDto
            {
                Games = games.Select(g => new GameOptionDto
                {
                    Id = g.Id,
                    Name = g.GameName,
                    Genre = g.Genre,
                    Positions = GameCatalog.PositionsOf(g.GameName),
                }).ToList(),
                Purposes = GamePurpose.All.Select(p => new OptionDto { Code = p, Label = GameCatalog.PurposeLabel(p) }).ToList(),
                PlayTimes = PlayTimeSlot.Labels.Select(kv => new OptionDto { Code = kv.Key, Label = kv.Value }).ToList(),
                Regions = GameCatalog.Regions.Select(r => new OptionDto { Code = r, Label = GameCatalog.RegionLabel(r) }).ToList(),
                Hobbies = hobbies.Select(h => new HobbyOptionDto { Id = h.Id, Name = h.Name }).ToList(),
            };
        }

        public async Task<OnboardingRequest> GetAnswersAsync(Guid userId)
        {
            var profile = await _context.UserProfiles.AsNoTracking().FirstOrDefaultAsync(p => p.UserId == userId);

            return new OnboardingRequest
            {
                Games = await _context.UserGameProfiles
                    .Where(g => g.UserId == userId)
                    .Select(g => new OnboardingGameDto { GameId = g.GameId, Position = g.PreferredPosition, Purpose = g.Purpose ?? GamePurpose.Fun })
                    .ToListAsync(),
                PlayTimes = await _context.UserPlayTimes.Where(t => t.UserId == userId).Select(t => t.Slot).ToListAsync(),
                Region = profile?.Region ?? string.Empty,
                UsesMic = profile?.UsesMic,
                HobbyIds = await _context.UserHobbies.Where(h => h.UserId == userId).Select(h => h.HobbyId).ToListAsync(),
                TeammateWish = profile?.TeammateWish,
            };
        }

        public async Task<ServiceResult<UserDto>> SaveAsync(Guid userId, OnboardingRequest request)
        {
            var profile = await _context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
            if (profile == null)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy hồ sơ người dùng!");
            }

            // Kiểm tra dữ liệu mà [Required]/[RegularExpression] trong DTO không tự kiểm tra được
            var gameIds = request.Games.Select(g => g.GameId).ToList();
            if (gameIds.Distinct().Count() != gameIds.Count)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, "Mỗi game chỉ chọn 1 lần.");
            }
            var validGameCount = await _context.Games.CountAsync(g => gameIds.Contains(g.Id) && g.IsActive);
            if (validGameCount != gameIds.Count)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, "Có game không tồn tại hoặc đã ngừng hỗ trợ.");
            }

            var playTimes = request.PlayTimes.Distinct().ToList();
            if (playTimes.Any(t => !PlayTimeSlot.Labels.ContainsKey(t)))
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, "Khung giờ chơi không hợp lệ.");
            }

            var hobbyIds = request.HobbyIds.Distinct().ToList();
            var validHobbyCount = await _context.Hobbies.CountAsync(h => hobbyIds.Contains(h.Id));
            if (validHobbyCount != hobbyIds.Count)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status400BadRequest, "Có sở thích không tồn tại.");
            }

            var now = DateTime.UtcNow;

            // Ghi đè: xóa lựa chọn cũ rồi thêm lựa chọn mới, gói trong 1 transaction để lỗi giữa chừng không mất dữ liệu cũ
            await using var transaction = await _context.Database.BeginTransactionAsync();
            await _context.UserGameProfiles.Where(g => g.UserId == userId).ExecuteDeleteAsync();
            await _context.UserPlayTimes.Where(t => t.UserId == userId).ExecuteDeleteAsync();
            await _context.UserHobbies.Where(h => h.UserId == userId).ExecuteDeleteAsync();

            _context.UserGameProfiles.AddRange(request.Games.Select(g => new UserGameProfile
            {
                UserId = userId,
                GameId = g.GameId,
                PreferredPosition = string.IsNullOrWhiteSpace(g.Position) ? null : g.Position.Trim(),
                Purpose = g.Purpose,
                UpdatedAt = now,
            }));
            _context.UserPlayTimes.AddRange(playTimes.Select(t => new UserPlayTime { UserId = userId, Slot = t }));
            _context.UserHobbies.AddRange(hobbyIds.Select(id => new UserHobby { UserId = userId, HobbyId = id }));

            profile.Region = request.Region;
            profile.UsesMic = request.UsesMic;
            profile.TeammateWish = string.IsNullOrWhiteSpace(request.TeammateWish) ? null : request.TeammateWish.Trim();
            profile.OnboardingCompletedAt ??= now;
            profile.UpdatedAt = now;

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            return ServiceResult<UserDto>.Ok((await _userService.GetUserDtoAsync(userId))!);
        }
    }
}
