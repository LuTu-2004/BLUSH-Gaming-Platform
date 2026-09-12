-- ============================================================================
-- MASTER DATABASE SCRIPT: BLUSH AI GAMING PLATFORM (HYBRID VERSION)
-- RDBMS: SQL Server | Combined Architecture (Standard 3NF + UI Matching)
-- Ngày cập nhật: 12/09/2026
-- ============================================================================

CREATE DATABASE BlushDb;
GO
USE BlushDb;
GO

-- =============================================
-- 1. MODULE NGƯỜI DÙNG & PHÂN QUYỀN
-- =============================================

CREATE TABLE Roles (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE -- 'User', 'Staff', 'Admin'
);

CREATE TABLE VipPackages (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    PackageCode VARCHAR(50) NOT NULL UNIQUE, -- 'month_basic', 'month_pro'
    PackageName NVARCHAR(100) NOT NULL,       -- 'BLUSH Pass', 'BLUSH Pass Pro'
    Price DECIMAL(18,2) NOT NULL,
    AiTokenLimit INT NOT NULL,
    Description NVARCHAR(MAX),
    Badge NVARCHAR(50) NULL
);

CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RoleId INT NOT NULL FOREIGN KEY REFERENCES Roles(Id),
    Email VARCHAR(255) NOT NULL UNIQUE,
    PasswordHash VARCHAR(MAX) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Age INT CHECK (Age >= 18),
    MBTI VARCHAR(10),
    Bio NVARCHAR(500),
    Lifestyle NVARCHAR(255),
    Hobbies NVARCHAR(255),
    
    -- UI Details
    OverthinkAnswer NVARCHAR(500) NULL,
    SundayAnswer NVARCHAR(500) NULL,
    AvatarEmoji NVARCHAR(50) DEFAULT '🎮',
    AvatarFrame NVARCHAR(100) DEFAULT 'Normal',
    
    -- Gamification
    CurrentLevel INT DEFAULT 1,
    Exp INT DEFAULT 0,
    Coins INT DEFAULT 0,
    
    -- VIP & Status
    VipPackageId INT NULL FOREIGN KEY REFERENCES VipPackages(Id),
    VipExpireDate DATETIME2 NULL,
    IsBanned BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- 2. MODULE GAME & HỆ THỐNG MATCHING (ZONE)
-- =============================================

CREATE TABLE Games (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    GameName NVARCHAR(100) NOT NULL, -- Liên Quân Mobile, Valorant, LMHT...
    IconUrl VARCHAR(500)
);

CREATE TABLE Zones (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    GameId INT NOT NULL FOREIGN KEY REFERENCES Games(Id),
    ZoneName NVARCHAR(100) NOT NULL, -- Chúa Tryhard, Hội Tấu Hài...
    Purpose NVARCHAR(100),
    IsVipOnly BIT DEFAULT 0,
    Description NVARCHAR(500)
);

-- Kết quả khảo sát AI ban đầu của User
CREATE TABLE UserGameProfiles (
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    GameId INT NOT NULL FOREIGN KEY REFERENCES Games(Id),
    PreferredPosition NVARCHAR(50), -- Mid, Rung, Top...
    PlayStyle NVARCHAR(100),       -- Tryhard, Tấu hài...
    PRIMARY KEY (UserId, GameId)
);

-- =============================================
-- 3. MODULE PHÒNG CHAT & ICE-BREAKER
-- =============================================

CREATE TABLE IceBreakerQuestions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Category NVARCHAR(100),
    QuestionTextVI NVARCHAR(500) NOT NULL,
    QuestionTextEN NVARCHAR(500),
    OptionA NVARCHAR(255) NOT NULL,
    OptionB NVARCHAR(255) NOT NULL,
    OptionA_Icon NVARCHAR(50) DEFAULT '🛡️',
    OptionB_Icon NVARCHAR(50) DEFAULT '👑',
    IsActive BIT DEFAULT 1
);

CREATE TABLE ChatRooms (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ZoneId INT NULL FOREIGN KEY REFERENCES Zones(Id),
    User1Id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    User2Id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    IceBreakerQuestionId INT NULL FOREIGN KEY REFERENCES IceBreakerQuestions(Id),
    User1Choice NVARCHAR(10) NULL, -- 'OptionA' hoặc 'OptionB'
    User2Choice NVARCHAR(10) NULL,
    IsIceBroken BIT DEFAULT 0,    -- Đã qua vòng phá băng chưa
    Status VARCHAR(50) DEFAULT 'Active', -- Active, Closed
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Messages (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RoomId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES ChatRooms(Id) ON DELETE CASCADE,
    SenderId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES Users(Id), -- NULL nếu là AI Assistant
    Content NVARCHAR(MAX) NOT NULL,
    IsAiGenerated BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- 4. MODULE GAMIFICATION (NHIỆM VỤ)
-- =============================================

CREATE TABLE Quests (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TitleVI NVARCHAR(255) NOT NULL,
    TitleEN NVARCHAR(255) NULL,
    DescVI NVARCHAR(500) NULL,
    QuestType VARCHAR(50) NOT NULL, -- Daily, Weekly, Seasonal
    TargetCount INT NOT NULL DEFAULT 1,
    RewardExp INT NOT NULL DEFAULT 25,
    RewardCoins INT NOT NULL DEFAULT 10,
    IsActive BIT DEFAULT 1
);

CREATE TABLE UserQuests (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
    QuestId INT NOT NULL FOREIGN KEY REFERENCES Quests(Id) ON DELETE CASCADE,
    CurrentProgress INT DEFAULT 0,
    IsCompleted BIT DEFAULT 0,
    IsClaimed BIT DEFAULT 0, -- Đã bấm nhận thưởng trên UI chưa
    CompletedAt DATETIME2 NULL,
    ClaimedAt DATETIME2 NULL
);

-- =============================================
-- 5. MODULE STAFF & ADMIN (BÁO CÁO & THANH TOÁN)
-- =============================================

CREATE TABLE Reports (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ReporterId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    ReportedUserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Reason NVARCHAR(500) NOT NULL,
    Severity VARCHAR(50) NOT NULL DEFAULT 'Medium', -- High, Medium, Low
    Status VARCHAR(50) DEFAULT 'Pending',          -- Pending, Resolved, Dismissed
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Transactions (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderCode BIGINT NULL, -- Mã đối soát PayOS VietQR
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    VipPackageId INT NOT NULL FOREIGN KEY REFERENCES VipPackages(Id),
    Amount DECIMAL(18,2) NOT NULL,
    PaymentMethod VARCHAR(50) DEFAULT 'VietQR_PayOS',
    Status VARCHAR(50) DEFAULT 'Processing', -- Processing, Success, Failed
    CreatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================
-- DỮ LIỆU MẪU KHỞI TẠO (SEED DATA MẶC ĐỊNH)
-- =============================================

-- 1. Seed Roles
INSERT INTO Roles (RoleName) VALUES ('User'), ('Staff'), ('Admin');

-- 2. Seed VipPackages
INSERT INTO VipPackages (PackageCode, PackageName, Price, AiTokenLimit, Description, Badge) VALUES
('month_basic', N'BLUSH Pass', 29000, 50000, N'Gói cơ bản sinh viên', NULL),
('month_pro', N'BLUSH Pass Pro', 49000, 150000, N'Gói Pro đầy đủ quyền lợi', N'PHỔ BIẾN NHẤT 🔥');

-- 3. Seed Default Accounts (Admin, Staff & User mẫu)
-- Note: PasswordHash mẫu dùng giá trị mã hóa bcrypt của '123456'
INSERT INTO Users (Id, RoleId, Email, PasswordHash, FullName, Age, MBTI, Bio, CurrentLevel, Exp, Coins, VipPackageId, VipExpireDate) VALUES
('11111111-1111-1111-1111-111111111111', 3, 'admin@blush.vn', '$2a$11$e8zN7wN8H2gR7wX8Y9Z0UeX8Y9Z0UeX8Y9Z0UeX8Y9Z0UeX8Y9Z0U', N'Super Admin', 25, 'ENTJ', N'Quản trị viên hệ thống BLUSH', 99, 99999, 99999, 2, '2030-12-31'),
('22222222-2222-2222-2222-222222222222', 2, 'staff@blush.vn', '$2a$11$e8zN7wN8H2gR7wX8Y9Z0UeX8Y9Z0UeX8Y9Z0UeX8Y9Z0UeX8Y9Z0U', N'Hùng Moderator', 22, 'ISTJ', N'Kiểm duyệt viên phòng chat & sự kiện', 20, 2100, 500, 2, '2027-12-31'),
('33333333-3333-3333-3333-333333333333', 1, 'gamer@blush.vn', '$2a$11$e8zN7wN8H2gR7wX8Y9Z0UeX8Y9Z0UeX8Y9Z0UeX8Y9Z0UeX8Y9Z0U', N'Lưu Phước Nhật Tú', 20, 'INFJ', N'Mê game tấu hài & ca hát voice chat', 12, 1250, 340, NULL, NULL);

-- 4. Seed Default Games (Do Admin quản lý)
INSERT INTO Games (GameName, IconUrl) VALUES 
(N'Liên Quân Mobile', '/icons/lienquan.png'),
(N'Valorant', '/icons/valorant.png'),
(N'LMHT', '/icons/lmht.png'),
(N'Đấu Trường Chân Lý', '/icons/tft.png');

-- 5. Seed Default Zones (Do Admin tạo)
INSERT INTO Zones (GameId, ZoneName, Purpose, IsVipOnly, Description) VALUES
(1, N'Sảnh Tấu Hài Liên Quân', N'Hội Tấu Hài', 0, N'Giải trí, voice chat ca hát xả stress'),
(1, N'Chúa Tryhard Leo Rank', N'Chúa Tryhard', 0, N'Leo rank nghiêm túc cấm chọn theo meta'),
(2, N'Sảnh Tryhard Valorant', N'Chúa Tryhard', 0, N'Cần Duelist ngắm chuẩn mic rõ'),
(3, N'Sảnh VIP Pro-Player Mentors', N'Chúa Tryhard', 1, N'Phòng kín VIP có Coach 1-1');

-- 6. Seed Default Quests
INSERT INTO Quests (TitleVI, TitleEN, DescVI, QuestType, TargetCount, RewardExp, RewardCoins) VALUES
(N'Ghép đội 1 lần', 'Match 1 time', N'Sử dụng AI Matching để tìm đồng đội', 'Daily', 1, 25, 10),
(N'Đăng 1 bài trên Feed', 'Post on Feed', N'Chia sẻ chiến tích hoặc chiến thuật', 'Daily', 1, 30, 15),
(N'Đạt chuỗi 3 trận thắng', '3 Win Streak', N'Cùng đồng đội ghép sảnh thắng liên tiếp 3 trận', 'Weekly', 3, 250, 100);

PRINT N'✅ Khởi tạo CSDL BlushDb bản Master (đã bao gồm Seed Tài khoản Admin & Staff mặc định) thành công!';
GO
