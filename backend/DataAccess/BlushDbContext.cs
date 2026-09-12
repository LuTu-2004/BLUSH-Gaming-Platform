using Microsoft.EntityFrameworkCore;
using Blush.Api.DataAccess.Entities;

namespace Blush.Api.DataAccess
{
    // ============================================================
    // LAYER 3: DATA ACCESS LAYER - EF Core DbContext SQL Server
    // ============================================================
    public class BlushDbContext : DbContext
    {
        public BlushDbContext(DbContextOptions<BlushDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Seed dữ liệu mẫu cho SQL Server
            modelBuilder.Entity<User>().HasData(
                new User { Id = "u1", Name = "Khánh Linh", Age = 20, Mbti = "INFJ", Game = "Liên Quân Mobile", Lane = "Đường Giữa", Purpose = "Hội Tấu Hài", Coins = 340, Exp = 1250, Level = 12, IsVip = false },
                new User { Id = "u2", Name = "Minh Tú", Age = 22, Mbti = "ENFP", Game = "Liên Quân Mobile", Lane = "Đường Rừng", Purpose = "Chúa Tryhard", Coins = 1500, Exp = 4200, Level = 28, IsVip = true }
            );
        }
    }
}
