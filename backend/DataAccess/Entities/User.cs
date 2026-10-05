namespace Blush.Api.DataAccess.Entities
{
    // ============================================================
    // LAYER 3: DATA ACCESS LAYER - Bảng [Users] (tài khoản đăng nhập + điểm game)
    // Phải khớp 100% với database/script_database.sql
    // ============================================================
    public class User
    {
        public Guid Id { get; set; }
        public int RoleId { get; set; } = Role.UserId;
        public string Email { get; set; } = string.Empty;
        public bool EmailConfirmed { get; set; }
        public string? PasswordHash { get; set; } // null nếu chỉ đăng nhập bằng Google

        public string Status { get; set; } = UserStatus.Active;
        public DateTime? SuspendedUntil { get; set; }

        public int Exp { get; set; }
        public int Coins { get; set; }
        public int CurrentLevel { get; private set; } // SQL tự tính = Exp / 100 + 1
        public DateOnly? LastCheckInDate { get; set; }

        // Chống dò mật khẩu
        public int FailedLoginCount { get; set; }
        public DateTime? LockoutEndAt { get; set; }

        // Xác thực 2 bước qua email (người dùng tự bật)
        public bool TwoFactorEnabled { get; set; }

        public DateTime? LastLoginAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public Role Role { get; set; } = null!;
        public UserProfile? Profile { get; set; }
        public List<UserLogin> Logins { get; set; } = new();
        public List<UserSubscription> Subscriptions { get; set; } = new();
        public List<UserGameProfile> GameProfiles { get; set; } = new();
        public List<UserHobby> Hobbies { get; set; } = new();
        public List<UserPlayTime> PlayTimes { get; set; } = new();
    }

    // Giá trị hợp lệ của cột Users.Status (khớp CHECK trong SQL)
    public static class UserStatus
    {
        public const string Active = "Active";
        public const string Suspended = "Suspended";
        public const string Banned = "Banned";
    }
}
