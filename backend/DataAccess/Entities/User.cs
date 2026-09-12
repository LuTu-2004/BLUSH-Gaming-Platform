namespace Blush.Api.DataAccess.Entities
{
    // ============================================================
    // LAYER 3: DATA ACCESS LAYER - User Entity (Bảng SQL Server)
    // Dành cho Backend Dev làm việc với CSDL
    // ============================================================
    public class User
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Name { get; set; } = string.Empty;
        public int Age { get; set; }
        public string Mbti { get; set; } = "INFJ";
        public string Game { get; set; } = "Liên Quân Mobile";
        public string Lane { get; set; } = "Đường Giữa";
        public string Purpose { get; set; } = "Hội Tấu Hài";
        public int Coins { get; set; } = 340;
        public int Exp { get; set; } = 1250;
        public int Level { get; set; } = 12;
        public bool IsVip { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
