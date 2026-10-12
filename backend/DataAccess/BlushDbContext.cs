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
        public DbSet<TrustedDevice> TrustedDevices => Set<TrustedDevice>();
        public DbSet<Game> Games => Set<Game>();
        public DbSet<Hobby> Hobbies => Set<Hobby>();
        public DbSet<UserGameProfile> UserGameProfiles => Set<UserGameProfile>();
        public DbSet<UserHobby> UserHobbies => Set<UserHobby>();
        public DbSet<UserPlayTime> UserPlayTimes => Set<UserPlayTime>();
        public DbSet<Transaction> Transactions => Set<Transaction>();
        public DbSet<Quest> Quests => Set<Quest>();
        public DbSet<UserQuest> UserQuests => Set<UserQuest>();
        public DbSet<Report> Reports => Set<Report>();
        public DbSet<IceBreakerQuestion> IceBreakerQuestions => Set<IceBreakerQuestion>();
        public DbSet<ChatRoom> ChatRooms => Set<ChatRoom>();
        public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
        public DbSet<UserBlock> UserBlocks => Set<UserBlock>();
        public DbSet<AiLog> AiLogs => Set<AiLog>();
        public DbSet<Zone> Zones => Set<Zone>();
        public DbSet<UserZone> UserZones => Set<UserZone>();
        public DbSet<Post> Posts => Set<Post>();
        public DbSet<PostLike> PostLikes => Set<PostLike>();
        public DbSet<PostComment> PostComments => Set<PostComment>();

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
                entity.HasMany(u => u.GameProfiles).WithOne().HasForeignKey(g => g.UserId);
                entity.HasMany(u => u.Hobbies).WithOne().HasForeignKey(h => h.UserId);
                entity.HasMany(u => u.PlayTimes).WithOne().HasForeignKey(p => p.UserId);
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

            modelBuilder.Entity<Transaction>(entity =>
            {
                entity.Property(t => t.Amount).HasColumnType("decimal(18,2)");
                entity.Property(t => t.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.HasOne(t => t.VipPackage).WithMany().HasForeignKey(t => t.VipPackageId);
                entity.HasOne<User>().WithMany().HasForeignKey(t => t.UserId);
            });

            modelBuilder.Entity<EmailOtp>()
                .Property(o => o.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            modelBuilder.Entity<TrustedDevice>()
                .Property(d => d.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            modelBuilder.Entity<UserGameProfile>(entity =>
            {
                entity.HasKey(g => new { g.UserId, g.GameId });
                entity.HasOne(g => g.Game).WithMany().HasForeignKey(g => g.GameId);
            });

            modelBuilder.Entity<UserHobby>(entity =>
            {
                entity.HasKey(h => new { h.UserId, h.HobbyId });
                entity.HasOne(h => h.Hobby).WithMany().HasForeignKey(h => h.HobbyId);
            });

            modelBuilder.Entity<UserPlayTime>()
                .HasKey(p => new { p.UserId, p.Slot });

            modelBuilder.Entity<UserQuest>(entity =>
            {
                entity.HasOne(uq => uq.Quest).WithMany().HasForeignKey(uq => uq.QuestId);
                entity.HasOne<User>().WithMany().HasForeignKey(uq => uq.UserId);
            });

            modelBuilder.Entity<Report>(entity =>
            {
                entity.Property(r => r.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.HasOne<User>().WithMany().HasForeignKey(r => r.ReporterId).OnDelete(DeleteBehavior.NoAction);
                entity.HasOne<User>().WithMany().HasForeignKey(r => r.ReportedUserId).OnDelete(DeleteBehavior.NoAction);
                entity.HasOne<User>().WithMany().HasForeignKey(r => r.ResolvedBy).OnDelete(DeleteBehavior.NoAction);
            });

            modelBuilder.Entity<ChatRoom>(entity =>
            {
                entity.Property(r => r.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.HasOne(r => r.IceBreakerQuestion).WithMany().HasForeignKey(r => r.IceBreakerQuestionId);
                entity.HasOne<User>().WithMany().HasForeignKey(r => r.User1Id).OnDelete(DeleteBehavior.NoAction);
                entity.HasOne<User>().WithMany().HasForeignKey(r => r.User2Id).OnDelete(DeleteBehavior.NoAction);
            });

            modelBuilder.Entity<UserBlock>(entity =>
            {
                entity.HasKey(b => new { b.BlockerId, b.BlockedId });
                entity.Property(b => b.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.HasOne<User>().WithMany().HasForeignKey(b => b.BlockerId).OnDelete(DeleteBehavior.NoAction);
                entity.HasOne<User>().WithMany().HasForeignKey(b => b.BlockedId).OnDelete(DeleteBehavior.NoAction);
            });

            modelBuilder.Entity<Zone>().HasOne(z => z.Game).WithMany().HasForeignKey(z => z.GameId);
            modelBuilder.Entity<UserZone>(entity =>
            {
                entity.HasKey(m => new { m.UserId, m.ZoneId });
                entity.Property(m => m.JoinedAt).HasDefaultValueSql("SYSUTCDATETIME()");
            });
            modelBuilder.Entity<Post>().Property(p => p.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
            modelBuilder.Entity<PostLike>(entity =>
            {
                entity.HasKey(l => new { l.PostId, l.UserId });
                entity.Property(l => l.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
            });
            modelBuilder.Entity<PostComment>().Property(c => c.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            modelBuilder.Entity<AiLog>(entity =>
            {
                entity.Property(l => l.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.HasOne<User>().WithMany().HasForeignKey(l => l.UserId);
            });

            modelBuilder.Entity<ChatMessage>(entity =>
            {
                entity.ToTable("Messages");
                entity.HasOne<ChatRoom>().WithMany().HasForeignKey(m => m.RoomId);
            });
        }
    }
}
