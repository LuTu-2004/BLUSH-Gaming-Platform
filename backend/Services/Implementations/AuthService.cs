using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Đăng ký / Đăng nhập / Xác minh email / Quên mật khẩu
    // ============================================================
    public class AuthService : IAuthService
    {
        private const int BcryptWorkFactor = 11;
        private const int MaxFailedLogins = 5;
        private static readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);

        // Cùng 1 câu cho "sai email" và "sai mật khẩu" để kẻ xấu không dò được email nào đã đăng ký
        private const string InvalidCredentials = "Email hoặc mật khẩu không đúng.";
        private const string CodeExpired = "Mã đã hết hạn. Vui lòng bấm \"Gửi lại mã\".";

        private readonly BlushDbContext _context;
        private readonly ITokenService _tokenService;
        private readonly IGoogleTokenValidator _googleValidator;
        private readonly IUserService _userService;
        private readonly IOtpService _otpService;
        private readonly ITrustedDeviceService _trustedDevices;
        private readonly ILogger<AuthService> _logger;

        public AuthService(BlushDbContext context, ITokenService tokenService, IGoogleTokenValidator googleValidator,
            IUserService userService, IOtpService otpService, ITrustedDeviceService trustedDevices, ILogger<AuthService> logger)
        {
            _context = context;
            _tokenService = tokenService;
            _googleValidator = googleValidator;
            _userService = userService;
            _otpService = otpService;
            _trustedDevices = trustedDevices;
            _logger = logger;
        }

        // ─────────────────────────── ĐĂNG KÝ ───────────────────────────

        public async Task<ServiceResult<MessageResponse>> RegisterAsync(RegisterRequest request)
        {
            var dob = request.DateOfBirth!.Value;
            var today = VietnamTime.Today;
            if (dob > today || dob.Year < 1900)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Ngày sinh không hợp lệ.");
            }
            if (!AgePolicy.IsOldEnough(dob, today))
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest,
                    $"BLUSH dành cho người từ {AgePolicy.MinimumAge} tuổi trở lên.");
            }

            var email = NormalizeEmail(request.Email);
            var user = await _context.Users.Include(u => u.Profile).Include(u => u.Logins)
                .FirstOrDefaultAsync(u => u.Email == email);

            if (user != null && (user.EmailConfirmed || user.Logins.Count > 0))
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status409Conflict, "Email này đã được đăng ký.");
            }

            var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password, BcryptWorkFactor);
            var displayName = Truncate(request.DisplayName.Trim(), 50);

            if (user == null)
            {
                user = NewUser(email, emailConfirmed: false);
                user.Profile = NewProfile(user.Id, displayName, avatarUrl: null);
                _context.Users.Add(user);
            }
            else
            {
                // Đã đăng ký trước đó nhưng chưa xác minh (VD: nhập sai email, đóng app) -> cho đăng ký lại
                user.UpdatedAt = DateTime.UtcNow;
                user.Profile ??= NewProfile(user.Id, displayName, avatarUrl: null);
                user.Profile.DisplayName = displayName;
            }
            user.PasswordHash = passwordHash;
            user.Profile.DateOfBirth = dob;
            await _context.SaveChangesAsync();

            var sent = await SendOtpAsync(user, OtpPurpose.VerifyEmail);
            if (!sent.Success) return Fail<MessageResponse>(sent);

            return ServiceResult<MessageResponse>.Ok(new MessageResponse
            {
                Message = $"Đã gửi mã xác minh 6 số tới {email}.",
                Email = email,
            });
        }

        public async Task<ServiceResult<AuthResponse>> VerifyEmailAsync(VerifyEmailRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == NormalizeEmail(request.Email));
            if (user == null)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status400BadRequest, CodeExpired);
            }
            if (user.EmailConfirmed)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status400BadRequest, "Email đã được xác minh. Vui lòng đăng nhập.");
            }

            var verified = await _otpService.VerifyAsync(user.Id, OtpPurpose.VerifyEmail, request.Code);
            if (!verified.Success) return Fail<AuthResponse>(verified);

            user.EmailConfirmed = true;
            return await CompleteLoginAsync(user, isNewUser: true);
        }

        public async Task<ServiceResult<MessageResponse>> ResendOtpAsync(ResendOtpRequest request)
        {
            if (!OtpPurpose.IsValid(request.Purpose))
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Loại mã không hợp lệ.");
            }

            var email = NormalizeEmail(request.Email);
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            bool shouldSend = user != null
                && !(request.Purpose == OtpPurpose.VerifyEmail && user.EmailConfirmed)
                && !(request.Purpose == OtpPurpose.TwoFactorLogin && !user.TwoFactorEnabled);
            if (shouldSend)
            {
                var sent = await SendOtpAsync(user!, request.Purpose);
                if (!sent.Success) return Fail<MessageResponse>(sent);
            }

            // Luôn trả cùng 1 câu, không để lộ email có tồn tại hay không
            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = $"Nếu {email} hợp lệ, mã mới đã được gửi.", Email = email });
        }

        // ─────────────────────────── ĐĂNG NHẬP ───────────────────────────

        public async Task<ServiceResult<AuthResponse>> LoginAsync(LoginRequest request)
        {
            var now = DateTime.UtcNow;
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == NormalizeEmail(request.Email));

            if (user == null)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status401Unauthorized, InvalidCredentials);
            }
            if (user.LockoutEndAt > now)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status429TooManyRequests, LockoutMessage(user.LockoutEndAt.Value, now));
            }
            if (user.PasswordHash == null)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status400BadRequest,
                    "Tài khoản này được tạo bằng Google. Hãy bấm \"Tiếp tục với Google\" hoặc \"Quên mật khẩu?\" để tạo mật khẩu.");
            }

            if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                user.FailedLoginCount++;
                if (user.FailedLoginCount >= MaxFailedLogins)
                {
                    user.FailedLoginCount = 0;
                    user.LockoutEndAt = now.Add(LockoutDuration);
                    await _context.SaveChangesAsync();
                    return ServiceResult<AuthResponse>.Fail(StatusCodes.Status429TooManyRequests, LockoutMessage(user.LockoutEndAt.Value, now));
                }
                await _context.SaveChangesAsync();
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status401Unauthorized, InvalidCredentials);
            }

            if (!user.EmailConfirmed)
            {
                user.FailedLoginCount = 0;
                await _context.SaveChangesAsync();
                await SendOtpAsync(user, OtpPurpose.VerifyEmail); // đang chờ 60 giây thì mã cũ vẫn dùng được
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status403Forbidden,
                    "Email chưa được xác minh. Vui lòng nhập mã 6 số đã gửi tới email của bạn.", ErrorCodes.EmailNotVerified);
            }

            // Xác thực 2 bước: đúng mật khẩu nhưng thiết bị chưa được tin cậy -> gửi mã về email
            if (user.TwoFactorEnabled && !await _trustedDevices.IsTrustedAsync(user.Id, request.DeviceToken))
            {
                user.FailedLoginCount = 0;
                await _context.SaveChangesAsync();
                var sent = await SendOtpAsync(user, OtpPurpose.TwoFactorLogin);
                // 429 = vừa gửi chưa quá 60 giây -> mã trước vẫn dùng được, không coi là lỗi
                if (!sent.Success && sent.StatusCode != StatusCodes.Status429TooManyRequests) return Fail<AuthResponse>(sent);

                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status403Forbidden,
                    "Tài khoản đã bật xác thực 2 bước. Nhập mã 6 số vừa gửi tới email của bạn.", ErrorCodes.TwoFactorRequired);
            }

            return await CompleteLoginAsync(user, isNewUser: false);
        }

        public async Task<ServiceResult<AuthResponse>> LoginWithTwoFactorAsync(TwoFactorLoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == NormalizeEmail(request.Email));
            if (user == null || !user.TwoFactorEnabled)
            {
                return ServiceResult<AuthResponse>.Fail(StatusCodes.Status400BadRequest, CodeExpired);
            }

            // Mã chỉ được gửi sau khi nhập ĐÚNG mật khẩu, nên có mã đúng = đã qua bước 1
            var verified = await _otpService.VerifyAsync(user.Id, OtpPurpose.TwoFactorLogin, request.Code);
            if (!verified.Success) return Fail<AuthResponse>(verified);

            var result = await CompleteLoginAsync(user, isNewUser: false);
            if (result.Success && request.RememberDevice)
            {
                result.Data!.DeviceToken = await _trustedDevices.CreateAsync(user.Id, request.DeviceName);
            }
            return result;
        }

        public async Task<ServiceResult<MessageResponse>> StartEnableTwoFactorAsync(Guid userId, string password)
        {
            var (user, error) = await FindUserAndCheckPasswordAsync(userId, password);
            if (user == null) return ServiceResult<MessageResponse>.Fail(error!.StatusCode, error.Error!);
            if (user.TwoFactorEnabled)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Xác thực 2 bước đang được bật rồi.");
            }

            // Gửi thử 1 mã: chắc chắn người dùng NHẬN được mã trước khi bật, tránh tự khóa mình ngoài tài khoản
            var sent = await SendOtpAsync(user, OtpPurpose.EnableTwoFactor);
            if (!sent.Success) return Fail<MessageResponse>(sent);

            return ServiceResult<MessageResponse>.Ok(new MessageResponse
            {
                Message = $"Đã gửi mã xác nhận tới {user.Email}.",
                Email = user.Email,
            });
        }

        public async Task<ServiceResult<UserDto>> ConfirmEnableTwoFactorAsync(Guid userId, string code)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return ServiceResult<UserDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người dùng!");
            }

            var verified = await _otpService.VerifyAsync(user.Id, OtpPurpose.EnableTwoFactor, code);
            if (!verified.Success) return Fail<UserDto>(verified);

            user.TwoFactorEnabled = true;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return ServiceResult<UserDto>.Ok((await _userService.GetUserDtoAsync(user.Id))!);
        }

        public async Task<ServiceResult<UserDto>> DisableTwoFactorAsync(Guid userId, string password)
        {
            var (user, error) = await FindUserAndCheckPasswordAsync(userId, password);
            if (user == null) return ServiceResult<UserDto>.Fail(error!.StatusCode, error.Error!);

            user.TwoFactorEnabled = false;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            await _trustedDevices.RevokeAllAsync(user.Id);
            return ServiceResult<UserDto>.Ok((await _userService.GetUserDtoAsync(user.Id))!);
        }

        // Nhập lại mật khẩu trước thao tác bảo mật: người khác cầm máy bạn cũng không tự bật/tắt được
        private async Task<(User? User, ServiceResult<bool>? Error)> FindUserAndCheckPasswordAsync(Guid userId, string password)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return (null, ServiceResult<bool>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người dùng!"));
            }
            if (user.PasswordHash == null)
            {
                return (null, ServiceResult<bool>.Fail(StatusCodes.Status400BadRequest,
                    "Tài khoản đăng nhập bằng Google đã được Google bảo vệ. Hãy tạo mật khẩu (Quên mật khẩu?) nếu muốn dùng xác thực 2 bước."));
            }
            if (!BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            {
                return (null, ServiceResult<bool>.Fail(StatusCodes.Status400BadRequest, "Mật khẩu hiện tại không đúng."));
            }
            return (user, null);
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

            // 3. Người dùng mới -> tạo tài khoản không mật khẩu.
            //    Google không cho biết ngày sinh -> TODO (bước 3): hỏi ngày sinh ở màn Khảo sát và chặn dưới AgePolicy.MinimumAge
            var user = NewUser(email, emailConfirmed: google.EmailVerified);
            var displayName = string.IsNullOrWhiteSpace(google.Name) ? email.Split('@')[0] : google.Name;
            user.Profile = NewProfile(user.Id, displayName, google.Picture);
            user.Logins.Add(NewGoogleLogin(user.Id, google.Subject));

            _context.Users.Add(user);
            return await CompleteLoginAsync(user, isNewUser: true);
        }

        // ─────────────────────────── QUÊN MẬT KHẨU ───────────────────────────

        public async Task<ServiceResult<MessageResponse>> ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            var email = NormalizeEmail(request.Email);
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user != null && user.Status != UserStatus.Banned)
            {
                var sent = await SendOtpAsync(user, OtpPurpose.ResetPassword);
                if (!sent.Success) return Fail<MessageResponse>(sent);
            }

            // Luôn trả cùng 1 câu, không để lộ email có tồn tại hay không
            return ServiceResult<MessageResponse>.Ok(new MessageResponse
            {
                Message = $"Nếu {email} đã đăng ký, mã đặt lại mật khẩu đã được gửi tới email đó.",
                Email = email,
            });
        }

        public async Task<ServiceResult<MessageResponse>> ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == NormalizeEmail(request.Email));
            if (user == null)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, CodeExpired);
            }

            var verified = await _otpService.VerifyAsync(user.Id, OtpPurpose.ResetPassword, request.Code);
            if (!verified.Success) return Fail<MessageResponse>(verified);

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword, BcryptWorkFactor);
            user.EmailConfirmed = true;     // nhận được mã qua email = đã chứng minh email là của mình
            user.FailedLoginCount = 0;
            user.LockoutEndAt = null;       // đổi mật khẩu xong thì mở khóa luôn
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            await _trustedDevices.RevokeAllAsync(user.Id); // đổi mật khẩu -> các thiết bị phải xác thực 2 bước lại

            return ServiceResult<MessageResponse>.Ok(new MessageResponse
            {
                Message = "Đặt lại mật khẩu thành công. Hãy đăng nhập bằng mật khẩu mới.",
                Email = user.Email,
            });
        }

        // ─────────────────────────── HÀM DÙNG CHUNG ───────────────────────────

        // Kiểm tra tài khoản có bị khóa không, reset đếm sai mật khẩu, cập nhật LastLoginAt rồi trả token
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

            user.FailedLoginCount = 0;
            user.LockoutEndAt = null;
            user.LastLoginAt = now;
            user.UpdatedAt = now;
            await _context.SaveChangesAsync();

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

        // Gửi OTP, bắt lỗi SMTP (sai mật khẩu Gmail, mất mạng...) để không trả lỗi 500 khó hiểu
        private async Task<ServiceResult<bool>> SendOtpAsync(User user, string purpose)
        {
            try
            {
                return await _otpService.SendAsync(user, purpose);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Gửi email OTP tới {Email} thất bại", user.Email);
                return ServiceResult<bool>.Fail(StatusCodes.Status503ServiceUnavailable, "Không gửi được email lúc này. Vui lòng thử lại sau.");
            }
        }

        private static ServiceResult<T> Fail<T>(ServiceResult<bool> from) =>
            ServiceResult<T>.Fail(from.StatusCode, from.Error!, from.ErrorCode);

        private static string LockoutMessage(DateTime lockoutEnd, DateTime now)
        {
            int minutes = (int)Math.Ceiling((lockoutEnd - now).TotalMinutes);
            return $"Bạn đã nhập sai mật khẩu quá {MaxFailedLogins} lần. Vui lòng thử lại sau {minutes} phút hoặc bấm \"Quên mật khẩu?\".";
        }

        private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

        private static string Truncate(string value, int max) => value.Length > max ? value[..max] : value;

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
            DisplayName = Truncate(displayName, 50),
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
