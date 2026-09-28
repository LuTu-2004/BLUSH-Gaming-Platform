using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Đăng ký / Đăng nhập (email + mật khẩu, Google)
    // ============================================================
    public class AuthService : IAuthService
    {
        private const int BcryptWorkFactor = 11;

        // Cùng 1 câu cho "sai email" và "sai mật khẩu" để kẻ xấu không dò được email nào đã đăng ký
        private const string InvalidCredentials = "Email hoặc mật khẩu không đúng.";

        private readonly BlushDbContext _context;
        private readonly ITokenService _tokenService;
        private readonly IGoogleTokenValidator _googleValidator;
        private readonly IUserService _userService;

        public AuthService(BlushDbContext context, ITokenService tokenService,
            IGoogleTokenValidator googleValidator, IUserService userService)
        {
            _context = context;
            _tokenService = tokenService;
            _googleValidator = googleValidator;
            _userService = userService;
        }

        public async Task<ServiceResult<AuthResponse>> RegisterAsync(RegisterRequest request)
        {
            var email = NormalizeEmail(request.Email);
            if (await _context.Users.AnyAsync(u => u.Email == email))
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status409Conflict, "Email này đã được đăng ký.");
            }

            var user = NewUser(email, emailConfirmed: false);
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password, BcryptWorkFactor);
            user.Profile = NewProfile(user.Id, request.DisplayName.Trim(), avatarUrl: null);

            _context.Users.Add(user);
            return await CompleteLoginAsync(user, isNewUser: true);
        }

        public async Task<ServiceResult<AuthResponse>> LoginAsync(LoginRequest request)
        {
            var email = NormalizeEmail(request.Email);
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status401Unauthorized, InvalidCredentials);
            }
            if (user.PasswordHash == null)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status400BadRequest,
                    "Tài khoản này được tạo bằng Google. Vui lòng bấm \"Đăng nhập với Google\".");
            }
            if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status401Unauthorized, InvalidCredentials);
            }

            return await CompleteLoginAsync(user, isNewUser: false);
        }

        public async Task<ServiceResult<AuthResponse>> LoginWithGoogleAsync(string idToken)
        {
            var google = await _googleValidator.ValidateAsync(idToken);
            if (google == null)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status401Unauthorized, "Đăng nhập Google không hợp lệ.");
            }

            // 1. Đã từng đăng nhập Google -> tìm theo mã Google (sub)
            var login = await _context.UserLogins
                .FirstOrDefaultAsync(l => l.Provider == UserLogin.Google && l.ProviderKey == google.Subject);
            if (login != null)
            {
                var existing = await _context.Users.FirstAsync(u => u.Id == login.UserId);
                return await CompleteLoginAsync(existing, isNewUser: false);
            }

            // 2. Email đã đăng ký bằng mật khẩu -> liên kết thêm Google vào tài khoản đó.
            //    Chỉ liên kết khi Google xác nhận email là thật (EmailVerified).
            var email = NormalizeEmail(google.Email);
            var userByEmail = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (userByEmail != null)
            {
                if (!google.EmailVerified)
                {
                    return ServiceResult<AuthResponse>.Fail(StatusCodes.Status409Conflict,
                        "Email đã được đăng ký. Vui lòng đăng nhập bằng mật khẩu.");
                }
                userByEmail.EmailConfirmed = true;
                userByEmail.Logins.Add(NewGoogleLogin(userByEmail.Id, google.Subject));
                return await CompleteLoginAsync(userByEmail, isNewUser: false);
            }

            // 3. Người dùng mới -> tạo tài khoản không mật khẩu
            var user = NewUser(email, emailConfirmed: google.EmailVerified);
            var displayName = string.IsNullOrWhiteSpace(google.Name) ? email.Split('@')[0] : google.Name;
            user.Profile = NewProfile(user.Id, displayName, google.Picture);
            user.Logins.Add(NewGoogleLogin(user.Id, google.Subject));

            _context.Users.Add(user);
            return await CompleteLoginAsync(user, isNewUser: true);
        }

        // Kiểm tra tài khoản có bị khóa không, cập nhật LastLoginAt rồi trả token
        private async Task<ServiceResult<AuthResponse>> CompleteLoginAsync(User user, bool isNewUser)
        {
            var now = DateTime.UtcNow;

            if (user.Status == UserStatus.Banned)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status403Forbidden, "Tài khoản đã bị khóa vĩnh viễn.");
            }
            if (user.Status == UserStatus.Suspended)
            {
                if (user.SuspendedUntil > now)
                {
                    var until = user.SuspendedUntil.Value.AddHours(7).ToString("HH:mm dd/MM/yyyy");
                    return ServiceResult<AuthResponse>.Fail(StatusCodes.Status403Forbidden, $"Tài khoản bị tạm khóa đến {until}.");
                }
                // Hết hạn tạm khóa -> tự mở lại
                user.Status = UserStatus.Active;
                user.SuspendedUntil = null;
            }

            user.LastLoginAt = now;
            user.UpdatedAt = now;
            await _context.SaveChangesAsync();

            return await BuildAuthResponseAsync(user, isNewUser);
        }

        private async Task<ServiceResult<AuthResponse>> BuildAuthResponseAsync(User user, bool isNewUser)
        {
            var userDto = await _userService.GetUserDtoAsync(user.Id);
            if (userDto == null)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status500InternalServerError, "Không đọc được thông tin tài khoản.");
            }

            var (token, expiresAt) = _tokenService.CreateAccessToken(user, userDto.Role);
            return ServiceResult<AuthResponse>.Ok(new AuthResponse
            {
                AccessToken = token,
                ExpiresAt = expiresAt,
                IsNewUser = isNewUser,
                User = userDto,
            });
        }

        private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

        private static User NewUser(string email, bool emailConfirmed)
        {
            var now = DateTime.UtcNow;
            return new User
            {
                Id = Guid.NewGuid(),
                Email = email,
                EmailConfirmed = emailConfirmed,
                RoleId = Role.UserId,
                Status = UserStatus.Active,
                CreatedAt = now,
                UpdatedAt = now,
            };
        }

        private static UserProfile NewProfile(Guid userId, string displayName, string? avatarUrl) => new()
        {
            UserId = userId,
            DisplayName = displayName.Length > 50 ? displayName[..50] : displayName,
            AvatarUrl = avatarUrl,
            UpdatedAt = DateTime.UtcNow,
        };

        private static UserLogin NewGoogleLogin(Guid userId, string googleSubject) => new()
        {
            Provider = UserLogin.Google,
            ProviderKey = googleSubject,
            UserId = userId,
            CreatedAt = DateTime.UtcNow,
        };
    }
}
