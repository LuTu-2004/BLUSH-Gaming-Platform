using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    // 1 dòng trong trang Người dùng của Admin
    public class AdminUserDto
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public string Role { get; set; } = string.Empty;   // User | Staff | Admin
        public string Status { get; set; } = string.Empty; // Active | Suspended | Banned
        public DateTime? SuspendedUntil { get; set; }
        public bool IsVip { get; set; }
        public int Level { get; set; }
        public int Exp { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastLoginAt { get; set; }
    }

    // Số liệu cho 3 thẻ KPI (tính trên toàn bộ người dùng, không theo bộ lọc)
    public class AdminUserStatsDto
    {
        public int Total { get; set; }
        public int Vip { get; set; }
        public int Locked { get; set; } // Banned + đang bị tạm khóa
    }

    public class AdminUserListDto : PagedResult<AdminUserDto>
    {
        public AdminUserStatsDto Stats { get; set; } = new();
    }

    public class UpdateUserStatusRequest
    {
        [Required(ErrorMessage = "Vui lòng chọn trạng thái.")]
        [RegularExpression("^(Active|Suspended|Banned)$", ErrorMessage = "Trạng thái không hợp lệ.")]
        public string Status { get; set; } = string.Empty;

        // Chỉ dùng khi Status = Suspended
        [Range(1, 365, ErrorMessage = "Số ngày tạm khóa từ 1 đến 365.")]
        public int? SuspendDays { get; set; }
    }

    public class UpdateUserRoleRequest
    {
        [Required(ErrorMessage = "Vui lòng chọn vai trò.")]
        [RegularExpression("^(User|Staff|Admin)$", ErrorMessage = "Vai trò không hợp lệ.")]
        public string Role { get; set; } = string.Empty;
    }
}
