using Microsoft.EntityFrameworkCore;
using Blush.Api.DataAccess.Entities;

namespace Blush.Api.DataAccess
{
    // ============================================================
    // LAYER 3: DATA ACCESS LAYER - EF Core DbContext SQL Server
    // Database được tạo bằng database/script_database.sql (không dùng EF Migrations),
    // nên ở đây chỉ khai báo cách ánh xạ class <-> bảng, không tạo bảng hay seed dữ liệu.
    // ============================================================
    public class BlushDbContext : DbContext
    {
        public BlushDbContext(DbContextOptions<BlushDbContext> options) : base(options) { }

        public DbSet<User> Users => Set<User>();
        public DbSet<Role> Roles => Set<Role>();
        public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
        public DbSet<UserLogin> UserLogins => Set<UserLogin>();
        public DbSet<UserSubscription> UserSubscriptions => Set<UserSubscription>();
        public DbSet<VipPackage> VipPackages => Set<VipPackage>();
        public DbSet<EmailOtp> EmailOtps => Set<EmailOtp>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>(entity =>
            {
                // SQL Server tự tính cột này, EF chỉ đọc lại sau khi lưu
                entity.Property(u => u.CurrentLevel).HasComputedColumnSql("[Exp] / 100 + 1", stored: true);
                entity.Property(u => u.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

                entity.HasOne(u => u.Role).WithMany().HasForeignKey(u => u.RoleId);
                entity.HasOne(u => u.Profile).WithOne().HasForeignKey<UserProfile>(p => p.UserId);
                entity.HasMany(u => u.Logins).WithOne().HasForeignKey(l => l.UserId);
                entity.HasMany(u => u.Subscriptions).WithOne().HasForeignKey(s => s.UserId);
            });

            modelBuilder.Entity<UserProfile>(entity =>
            {
                entity.HasKey(p => p.UserId);
                entity.Property(p => p.Mbti).HasColumnName("MBTI");
            });

            modelBuilder.Entity<UserLogin>(entity =>
            {
                entity.HasKey(l => new { l.Provider, l.ProviderKey });
                entity.Property(l => l.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
            });

            modelBuilder.Entity<UserSubscription>()
                .Property(s => s.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            modelBuilder.Entity<VipPackage>()
                .Property(p => p.Price).HasColumnType("decimal(18,2)");

            modelBuilder.Entity<EmailOtp>()
                .Property(o => o.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
        }
    }
}
