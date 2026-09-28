namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Roles]. Id cố định theo dữ liệu mẫu trong script SQL.
    public class Role
    {
        public const int UserId = 1;
        public const int StaffId = 2;
        public const int AdminId = 3;

        public int Id { get; set; }
        public string RoleName { get; set; } = string.Empty;
    }
}
