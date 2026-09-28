-- ============================================================================
-- MASTER DATABASE SCRIPT: BLUSH AI GAMING PLATFORM (v2)
-- RDBMS: SQL Server
-- Quy ước:
--   * Thời gian lưu theo UTC (SYSUTCDATETIME). Frontend tự đổi sang giờ Việt Nam.
--   * Cột trạng thái dùng VARCHAR + CHECK để chặn giá trị gõ sai.
--   * Dữ liệu thanh toán (Transactions) KHÔNG bao giờ xóa dây chuyền theo User.
-- ============================================================================

-- Nếu đã có BlushDb cũ, bỏ comment 3 dòng dưới để XÓA và tạo lại từ đầu (mất hết dữ liệu!):
-- USE master;
-- ALTER DATABASE BlushDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
-- DROP DATABASE BlushDb;
-- GO

CREATE DATABASE BlushDb;
GO
USE BlushDb;
GO
-- Bắt buộc cho cột tính toán PERSISTED (SSMS bật sẵn, sqlcmd thì không)
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================
-- 1. MODULE TÀI KHOẢN & HỒ SƠ
-- =============================================

CREATE TABLE Roles (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(20) NOT NULL UNIQUE -- 'User', 'Staff', 'Admin'
);

-- Tài khoản đăng nhập: chỉ chứa thông tin xác thực + điểm game
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    RoleId INT NOT NULL DEFAULT 1 FOREIGN KEY REFERENCES Roles(Id),
    Email VARCHAR(255) NOT NULL UNIQUE,
    EmailConfirmed BIT NOT NULL DEFAULT 0,
    PasswordHash VARCHAR(255) NULL,         -- NULL nếu chỉ đăng nhập bằng Google

    -- Trạng thái (Staff: Cảnh báo / Tạm khóa / Bỏ qua)
    Status VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (Status IN ('Active', 'Suspended', 'Banned')),
    SuspendedUntil DATETIME2 NULL,

    -- Gamification: Level tự tính từ EXP, không lưu tay để tránh lệch
    Exp INT NOT NULL DEFAULT 0 CHECK (Exp >= 0),
    Coins INT NOT NULL DEFAULT 0 CHECK (Coins >= 0),
    CurrentLevel AS (Exp / 100 + 1) PERSISTED,
    LastCheckInDate DATE NULL,              -- Ngày điểm danh gần nhất (theo giờ Việt Nam)

    -- Chống dò mật khẩu: sai 5 lần liên tiếp -> khóa đăng nhập 15 phút
    FailedLoginCount INT NOT NULL DEFAULT 0,
    LockoutEndAt DATETIME2 NULL,

    -- Xác thực 2 bước qua email (người dùng tự bật trong Hồ sơ)
    TwoFactorEnabled BIT NOT NULL DEFAULT 0,

    LastLoginAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Đăng nhập bằng bên thứ ba (Google, sau này có thể thêm Facebook...)
-- 1 User có thể liên kết nhiều cách đăng nhập
CREATE TABLE UserLogins (
    Provider VARCHAR(20) NOT NULL CHECK (Provider IN ('Google', 'Facebook')),
    ProviderKey VARCHAR(255) NOT NULL,      -- Mã định danh do Google cấp (claim "sub")
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY (Provider, ProviderKey)
);
CREATE INDEX IX_UserLogins_UserId ON UserLogins(UserId);

-- Mã OTP 6 số gửi qua email: xác minh email, đặt lại mật khẩu, đăng nhập 2 bước
-- Chỉ lưu bản băm (hash) của mã, không lưu mã gốc
CREATE TABLE EmailOtps (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    Purpose VARCHAR(20) NOT NULL
        CONSTRAINT CK_EmailOtps_Purpose CHECK (Purpose IN ('VerifyEmail', 'ResetPassword', 'TwoFactorLogin', 'EnableTwoFactor')),
    CodeHash VARCHAR(100) NOT NULL,
    Attempts INT NOT NULL DEFAULT 0,        -- Nhập sai quá 5 lần -> mã bị hủy
    ExpiresAt DATETIME2 NOT NULL,           -- Hết hạn sau 10 phút
    ConsumedAt DATETIME2 NULL,              -- Đã dùng (hoặc bị thay bằng mã mới)
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_EmailOtps_User_Purpose ON EmailOtps(UserId, Purpose, CreatedAt);

-- Thiết bị đã tick "Tin cậy thiết bị này 30 ngày" -> đăng nhập không hỏi mã 2 bước
-- App giữ token gốc, DB chỉ lưu bản băm
CREATE TABLE TrustedDevices (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    TokenHash VARCHAR(100) NOT NULL UNIQUE,
    DeviceName NVARCHAR(100) NULL,
    ExpiresAt DATETIME2 NOT NULL,
    LastUsedAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_TrustedDevices_UserId ON TrustedDevices(UserId);

-- Hồ sơ hiển thị (quan hệ 1-1 với Users)
CREATE TABLE UserProfiles (
    UserId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    DisplayName NVARCHAR(50) NOT NULL,
    DateOfBirth DATE NULL,                  -- Tuổi tối thiểu (16) do backend kiểm tra: Services/AgePolicy.cs
                                            -- NULL = đăng nhập Google, chưa khai ngày sinh
    MBTI CHAR(4) NULL CHECK (MBTI LIKE '[EI][SN][TF][JP]'),
    Bio NVARCHAR(500) NULL,
    Lifestyle NVARCHAR(255) NULL,
    Region VARCHAR(10) NULL CHECK (Region IN ('HCM', 'HN')), -- Lọc Bảng xếp hạng theo server
    AvatarEmoji NVARCHAR(16) NOT NULL DEFAULT N'🎮',
    AvatarUrl VARCHAR(500) NULL,            -- Ảnh từ Google (ẩn khi bật Blind Profile)
    AvatarFrame VARCHAR(50) NOT NULL DEFAULT 'Normal',
    SundayAnswer NVARCHAR(500) NULL,        -- "Chủ nhật của bạn thường trông như thế nào?"
    OverthinkAnswer NVARCHAR(500) NULL,     -- "Điều gì khiến bạn overthink nhất?"
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Sở thích: tách bảng để Match Feed lọc được
CREATE TABLE Hobbies (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE UserHobbies (
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    HobbyId INT NOT NULL FOREIGN KEY REFERENCES Hobbies(Id) ON DELETE CASCADE,
    PRIMARY KEY (UserId, HobbyId)
);

-- =============================================
-- 2. MODULE GAME & ZONE
-- =============================================

CREATE TABLE Games (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    GameName NVARCHAR(100) NOT NULL UNIQUE,
    Genre NVARCHAR(50) NULL,
    IconUrl VARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

-- Purpose: 'Tryhard' (Chúa Tryhard), 'Fun' (Hội Tấu Hài), 'Event' (Thợ Săn Sự Kiện)
CREATE TABLE Zones (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    GameId INT NOT NULL FOREIGN KEY REFERENCES Games(Id),
    ZoneName NVARCHAR(100) NOT NULL,
    Purpose VARCHAR(20) NOT NULL CHECK (Purpose IN ('Tryhard', 'Fun', 'Event')),
    IsVipOnly BIT NOT NULL DEFAULT 0,
    Description NVARCHAR(500) NULL
);

-- Kết quả khảo sát AI: mỗi User có 1 dòng cho mỗi game
CREATE TABLE UserGameProfiles (
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    GameId INT NOT NULL FOREIGN KEY REFERENCES Games(Id),
    PreferredPosition NVARCHAR(50) NULL,    -- Mid, Rừng, Top...
    Purpose VARCHAR(20) NULL CHECK (Purpose IN ('Tryhard', 'Fun', 'Event')),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY (UserId, GameId)
);

-- =============================================
-- 3. MODULE CHAT & ICE-BREAKER
-- =============================================

CREATE TABLE IceBreakerQuestions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Category NVARCHAR(50) NOT NULL,         -- Strategy / Lobby Style / Team Role
    QuestionTextVI NVARCHAR(500) NOT NULL,
    QuestionTextEN NVARCHAR(500) NULL,
    OptionA NVARCHAR(255) NOT NULL,
    OptionB NVARCHAR(255) NOT NULL,
    OptionAIcon NVARCHAR(16) NOT NULL DEFAULT N'🛡️',
    OptionBIcon NVARCHAR(16) NOT NULL DEFAULT N'👑',
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Phòng chat 1-1. Backend phải kiểm tra cả 2 chiều (A,B) và (B,A) trước khi tạo phòng mới
CREATE TABLE ChatRooms (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    ZoneId INT NULL FOREIGN KEY REFERENCES Zones(Id),
    User1Id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    User2Id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    IceBreakerQuestionId INT NULL FOREIGN KEY REFERENCES IceBreakerQuestions(Id),
    User1Choice CHAR(1) NULL CHECK (User1Choice IN ('A', 'B')),
    User2Choice CHAR(1) NULL CHECK (User2Choice IN ('A', 'B')),
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active', 'Closed')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_ChatRooms_DifferentUsers CHECK (User1Id <> User2Id),
    CONSTRAINT UQ_ChatRooms_Pair UNIQUE (User1Id, User2Id)
);

CREATE TABLE Messages (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    RoomId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES ChatRooms(Id) ON DELETE CASCADE,
    SenderId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES Users(Id), -- NULL = tin nhắn của Trợ lý AI
    Content NVARCHAR(2000) NOT NULL,
    IsAiGenerated BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_Messages_Room_CreatedAt ON Messages(RoomId, CreatedAt);

-- =============================================
-- 4. MODULE GAMIFICATION (NHIỆM VỤ & HUY HIỆU)
-- =============================================

CREATE TABLE Quests (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TitleVI NVARCHAR(255) NOT NULL,
    TitleEN NVARCHAR(255) NULL,
    DescVI NVARCHAR(500) NULL,
    QuestType VARCHAR(20) NOT NULL CHECK (QuestType IN ('Daily', 'Weekly', 'Seasonal')),
    TargetCount INT NOT NULL DEFAULT 1 CHECK (TargetCount > 0),
    RewardExp INT NOT NULL DEFAULT 25 CHECK (RewardExp >= 0),
    RewardCoins INT NOT NULL DEFAULT 10 CHECK (RewardCoins >= 0),
    IsActive BIT NOT NULL DEFAULT 1
);

-- Tiến độ theo từng KỲ: PeriodStart = hôm nay (Daily), thứ Hai (Weekly), ngày đầu mùa (Seasonal)
-- Sang kỳ mới thì tạo dòng mới -> nhiệm vụ hằng ngày tự "reset"
CREATE TABLE UserQuests (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    QuestId INT NOT NULL FOREIGN KEY REFERENCES Quests(Id) ON DELETE CASCADE,
    PeriodStart DATE NOT NULL,
    CurrentProgress INT NOT NULL DEFAULT 0 CHECK (CurrentProgress >= 0),
    CompletedAt DATETIME2 NULL,             -- NULL = chưa xong
    ClaimedAt DATETIME2 NULL,               -- NULL = chưa bấm "Nhận quà"
    CONSTRAINT UQ_UserQuests_Period UNIQUE (UserId, QuestId, PeriodStart)
);

CREATE TABLE Badges (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code VARCHAR(50) NOT NULL UNIQUE,
    NameVI NVARCHAR(100) NOT NULL,
    NameEN NVARCHAR(100) NULL,
    Icon NVARCHAR(16) NOT NULL,
    Description NVARCHAR(255) NULL
);

CREATE TABLE UserBadges (
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    BadgeId INT NOT NULL FOREIGN KEY REFERENCES Badges(Id) ON DELETE CASCADE,
    EarnedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY (UserId, BadgeId)
);

-- =============================================
-- 5. MODULE AI (LOGS)
-- =============================================

CREATE TABLE AiLogs (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    FeatureType VARCHAR(50) NOT NULL
        CHECK (FeatureType IN ('ZoneClassification', 'ConversationStarter', 'DeadChatRescue', 'ProfileMatching')),
    PromptInput NVARCHAR(MAX) NULL,
    AiOutput NVARCHAR(MAX) NOT NULL,
    TokensUsed INT NOT NULL DEFAULT 0,      -- Số tokens Gemini đã dùng (để giới hạn theo gói)
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_AiLogs_User_CreatedAt ON AiLogs(UserId, CreatedAt);

-- =============================================
-- 6. MODULE VIP & THANH TOÁN
-- =============================================

CREATE TABLE VipPackages (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    PackageCode VARCHAR(50) NOT NULL UNIQUE, -- 'month_basic', 'month_pro'
    PackageName NVARCHAR(100) NOT NULL,
    Price DECIMAL(18,2) NOT NULL CHECK (Price >= 0),
    DurationDays INT NOT NULL DEFAULT 30 CHECK (DurationDays > 0),
    AiTokenLimit INT NOT NULL,
    Description NVARCHAR(500) NULL,
    Badge NVARCHAR(50) NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

-- Lịch sử giao dịch: không cascade theo User (chứng từ tài chính phải giữ lại)
CREATE TABLE Transactions (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    OrderCode BIGINT NOT NULL UNIQUE,       -- Mã đối soát với PayOS
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    VipPackageId INT NOT NULL FOREIGN KEY REFERENCES VipPackages(Id),
    Amount DECIMAL(18,2) NOT NULL CHECK (Amount >= 0),
    PaymentMethod VARCHAR(30) NOT NULL DEFAULT 'VietQR_PayOS',
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (Status IN ('Pending', 'Paid', 'Failed', 'Cancelled')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PaidAt DATETIME2 NULL
);
CREATE INDEX IX_Transactions_UserId ON Transactions(UserId);

-- Mỗi lần mua/gia hạn VIP là 1 dòng. User là VIP nếu có dòng EndAt > hiện tại.
-- TransactionId NULL = Admin cấp VIP thủ công
CREATE TABLE UserSubscriptions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    VipPackageId INT NOT NULL FOREIGN KEY REFERENCES VipPackages(Id),
    TransactionId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES Transactions(Id),
    StartAt DATETIME2 NOT NULL,
    EndAt DATETIME2 NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_UserSubscriptions_Dates CHECK (EndAt > StartAt)
);
CREATE INDEX IX_UserSubscriptions_User_EndAt ON UserSubscriptions(UserId, EndAt);

-- =============================================
-- 7. MODULE STAFF (BÁO CÁO VI PHẠM)
-- =============================================

CREATE TABLE Reports (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ReporterId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    ReportedUserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Reason NVARCHAR(500) NOT NULL,
    Severity VARCHAR(10) NOT NULL DEFAULT 'Medium' CHECK (Severity IN ('High', 'Medium', 'Low')),
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Resolved')),
    ActionTaken VARCHAR(20) NULL CHECK (ActionTaken IN ('Warn', 'Suspend', 'Dismiss')),
    ResolvedBy UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES Users(Id),
    ResolvedAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Reports_NotSelf CHECK (ReporterId <> ReportedUserId)
);
CREATE INDEX IX_Reports_Status ON Reports(Status, CreatedAt);
GO

-- =============================================
-- DỮ LIỆU MẪU (SEED DATA)
-- =============================================

INSERT INTO Roles (RoleName) VALUES ('User'), ('Staff'), ('Admin');

INSERT INTO VipPackages (PackageCode, PackageName, Price, DurationDays, AiTokenLimit, Description, Badge) VALUES
('month_basic', N'BLUSH Pass', 29000, 30, 50000, N'Gói cơ bản sinh viên', NULL),
('month_pro', N'BLUSH Pass Pro', 49000, 30, 150000, N'Gói Pro đầy đủ quyền lợi', N'PHỔ BIẾN NHẤT 🔥');

-- Tài khoản mẫu: mật khẩu đều là '123456' (BCrypt, cost 11)
INSERT INTO Users (Id, RoleId, Email, EmailConfirmed, PasswordHash, Exp, Coins) VALUES
('11111111-1111-1111-1111-111111111111', 3, 'admin@blush.vn', 1, '$2a$11$11bxfSM1RRJrN.Sx0udTGeHCK7P31lcH6ASAwi09Wy2bHUn5OkMOC', 9850, 99999),
('22222222-2222-2222-2222-222222222222', 2, 'staff@blush.vn', 1, '$2a$11$11bxfSM1RRJrN.Sx0udTGeHCK7P31lcH6ASAwi09Wy2bHUn5OkMOC', 1950, 500),
('33333333-3333-3333-3333-333333333333', 1, 'gamer@blush.vn', 1, '$2a$11$11bxfSM1RRJrN.Sx0udTGeHCK7P31lcH6ASAwi09Wy2bHUn5OkMOC', 1150, 340);

INSERT INTO UserProfiles (UserId, DisplayName, DateOfBirth, MBTI, Bio, Region, AvatarEmoji, SundayAnswer, OverthinkAnswer) VALUES
('11111111-1111-1111-1111-111111111111', N'Super Admin', '2001-03-15', 'ENTJ', N'Quản trị viên hệ thống BLUSH', 'HCM', N'⚡', NULL, NULL),
('22222222-2222-2222-2222-222222222222', N'Hùng Moderator', '2004-07-20', 'ISTJ', N'Kiểm duyệt viên phòng chat & sự kiện', 'HN', N'🛡️', NULL, NULL),
('33333333-3333-3333-3333-333333333333', N'Lưu Phước Nhật Tú', '2006-01-10', 'INFJ', N'Mê game tấu hài & ca hát voice chat', 'HCM', N'🎮',
    N'Ngủ tới 12h trưa rồi leo rank cùng anh em cả buổi chiều', N'Trận quan trọng mà team feed liên tục từ phút thứ 5');

INSERT INTO Hobbies (Name) VALUES
(N'Voice Chat'), (N'K-Pop'), (N'Anime'), (N'Âm nhạc'), (N'Tryhard'), (N'Co-op'), (N'Streaming'), (N'Cosplay');

INSERT INTO UserHobbies (UserId, HobbyId) VALUES
('33333333-3333-3333-3333-333333333333', 1),
('33333333-3333-3333-3333-333333333333', 4);

-- 6 tựa game theo tài liệu
INSERT INTO Games (GameName, Genre, IconUrl) VALUES
(N'Liên Quân Mobile', N'MOBA 5v5', '/icons/lienquan.png'),
(N'Valorant', N'FPS Tactical', '/icons/valorant.png'),
(N'LMHT', N'MOBA PC', '/icons/lmht.png'),
(N'Đấu Trường Chân Lý', N'Auto Battler', '/icons/tft.png'),
(N'PUBG Mobile', N'Battle Royale', '/icons/pubg.png'),
(N'Free Fire', N'Survival', '/icons/freefire.png');

-- 8 Zone cho 4 game chính
INSERT INTO Zones (GameId, ZoneName, Purpose, IsVipOnly, Description) VALUES
(1, N'Hội Tấu Hài Liên Quân', 'Fun', 0, N'Giải trí, voice chat ca hát xả stress'),
(1, N'Chúa Tryhard Liên Quân', 'Tryhard', 0, N'Leo rank nghiêm túc, chơi theo meta'),
(1, N'Thợ Săn Sự Kiện Liên Quân', 'Event', 0, N'Cày quest, săn skin sự kiện'),
(2, N'Sảnh Tryhard Valorant', 'Tryhard', 0, N'Cần Duelist ngắm chuẩn, mic rõ'),
(2, N'Hội Tấu Hài Valorant', 'Fun', 0, N'Bắn cho vui, cười là chính'),
(3, N'Chúa Tryhard LMHT', 'Tryhard', 0, N'Leo Kim Cương nghiêm túc'),
(3, N'Sảnh VIP Pro-Player Mentors', 'Tryhard', 1, N'Phòng kín VIP có Coach 1-1'),
(4, N'Hội Tấu Hài Đấu Trường Chân Lý', 'Fun', 0, N'Xếp đội hình dị, không toxic');

INSERT INTO UserGameProfiles (UserId, GameId, PreferredPosition, Purpose) VALUES
('33333333-3333-3333-3333-333333333333', 1, N'Đường Giữa', 'Fun');

INSERT INTO IceBreakerQuestions (Category, QuestionTextVI, QuestionTextEN, OptionA, OptionB, OptionAIcon, OptionBIcon) VALUES
(N'Strategy', N'Team thua 10 mạng đầu game, bạn sẽ?', N'Your team is down 10 kills early. You...', N'Thủ trụ chờ late game', N'All-in giao tranh lật kèo', N'🛡️', N'⚔️'),
(N'Lobby Style', N'Vào sảnh bạn thích?', N'In the lobby you prefer...', N'Bật mic tấu hài', N'Im lặng tập trung', N'🎤', N'🎧'),
(N'Team Role', N'Vai trò bạn hay nhận?', N'Your usual role?', N'Gánh team', N'Hỗ trợ đồng đội', N'👑', N'🤝');

INSERT INTO Quests (TitleVI, TitleEN, DescVI, QuestType, TargetCount, RewardExp, RewardCoins) VALUES
(N'Ghép đội 1 lần', 'Match 1 time', N'Sử dụng AI Matching để tìm đồng đội', 'Daily', 1, 25, 10),
(N'Đăng 1 bài trên Feed', 'Post on Feed', N'Chia sẻ chiến tích hoặc chiến thuật', 'Daily', 1, 30, 15),
(N'Like 5 bài viết', 'Like 5 posts', N'Tương tác xây dựng cộng đồng', 'Daily', 5, 15, 5),
(N'Chơi 3 trận cùng nhóm BLUSH', 'Play 3 matches with BLUSH team', N'Vào trận cùng đồng đội từ sảnh BLUSH', 'Daily', 3, 50, 20),
(N'Đạt chuỗi 3 trận thắng', '3 Win Streak', N'Thắng liên tiếp 3 trận cùng đồng đội', 'Weekly', 3, 250, 100),
(N'Hỗ trợ 5 tân thủ', 'Help 5 newbies', N'Ghép đội và hướng dẫn người mới', 'Weekly', 5, 200, 80),
(N'Đạt rank Cao Thủ', 'Reach Master rank', N'Leo lên Cao Thủ trong mùa giải', 'Seasonal', 1, 1000, 500),
(N'Tương tác 50 lần trên Feed', '50 Feed interactions', N'Bình luận, thả tim bài viết', 'Seasonal', 50, 500, 200);

INSERT INTO Badges (Code, NameVI, NameEN, Icon, Description) VALUES
('top1_fun', N'Top 1 Tấu Hài', 'Top 1 Fun', N'🥇', N'Đứng đầu Zone Hội Tấu Hài'),
('local_mvp', N'Local MVP', 'Local MVP', N'👑', N'MVP của server khu vực'),
('tryhard_king', N'Chúa Tryhard', 'Tryhard King', N'🔥', N'Hoàn thành 30 trận Tryhard');

INSERT INTO UserBadges (UserId, BadgeId) VALUES
('33333333-3333-3333-3333-333333333333', 1),
('33333333-3333-3333-3333-333333333333', 2);

-- Admin & Staff được cấp VIP Pro thủ công (TransactionId = NULL)
INSERT INTO UserSubscriptions (UserId, VipPackageId, TransactionId, StartAt, EndAt) VALUES
('11111111-1111-1111-1111-111111111111', 2, NULL, '2026-01-01', '2030-12-31'),
('22222222-2222-2222-2222-222222222222', 2, NULL, '2026-01-01', '2027-12-31');

PRINT N'✅ Khởi tạo CSDL BlushDb v2 thành công!';
GO
