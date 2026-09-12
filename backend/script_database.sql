-- ============================================================================
-- SCRIPT KHỞI TẠO CƠ SỞ DỮ LIỆU SQL SERVER - DỰ ÁN BLUSH GAMING PLATFORM
-- Môn học: EXE201 | Công nghệ: ASP.NET Core Web API 8 + EF Core + SQL Server
-- Ngày tạo: 12/09/2026
-- ============================================================================

CREATE DATABASE BlushDb;
GO

USE BlushDb;
GO

-- ============================================================================
-- 1. BẢNG NGƯỜI DÙNG & TÀI KHOẢN (Users)
-- ============================================================================
CREATE TABLE Users (
    Id NVARCHAR(450) NOT NULL PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NULL,
    Age INT NOT NULL DEFAULT 18,
    Mbti NVARCHAR(10) NOT NULL DEFAULT 'INFJ',
    Game NVARCHAR(100) NOT NULL DEFAULT N'Liên Quân Mobile',
    Lane NVARCHAR(50) NOT NULL DEFAULT N'Đường Giữa',
    Purpose NVARCHAR(50) NOT NULL DEFAULT N'Hội Tấu Hài',
    Coins INT NOT NULL DEFAULT 340,
    Exp INT NOT NULL DEFAULT 1250,
    Level INT NOT NULL DEFAULT 12,
    IsVip BIT NOT NULL DEFAULT 0,
    Role NVARCHAR(20) NOT NULL DEFAULT 'User', -- 'User', 'Staff', 'Admin'
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
GO

-- ============================================================================
-- 2. BẢNG HỒ SƠ CHI TIẾT NGƯỜI DÙNG (UserProfiles)
-- ============================================================================
CREATE TABLE UserProfiles (
    UserId NVARCHAR(450) NOT NULL PRIMARY KEY,
    Bio NVARCHAR(500) NULL,
    Lifestyle NVARCHAR(200) NULL,
    Hobbies NVARCHAR(200) NULL,
    OverthinkAnswer NVARCHAR(500) NULL,
    SundayAnswer NVARCHAR(500) NULL,
    AvatarEmoji NVARCHAR(50) NULL DEFAULT '🎮',
    AvatarFrame NVARCHAR(100) NULL DEFAULT 'Normal',
    BadgesJson NVARCHAR(MAX) NULL, -- Lưu danh sách huy hiệu dạng JSON
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);
GO

-- ============================================================================
-- 3. BẢNG PHÂN KHU / SẢNH GHÉP ĐỘI (Lobbies)
-- ============================================================================
CREATE TABLE Lobbies (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Game NVARCHAR(100) NOT NULL,
    Purpose NVARCHAR(50) NOT NULL,
    Description NVARCHAR(500) NULL,
    MaxPlayers INT NOT NULL DEFAULT 5,
    CurrentOnline INT NOT NULL DEFAULT 1,
    IsVipOnly BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
GO

-- ============================================================================
-- 4. BẢNG CÂU HỎI PHÁ BĂNG (IceBreakerQuestions)
-- ============================================================================
CREATE TABLE IceBreakerQuestions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    QuestionVi NVARCHAR(500) NOT NULL,
    QuestionEn NVARCHAR(500) NOT NULL,
    Category NVARCHAR(50) NOT NULL DEFAULT 'Strategy', -- 'Strategy', 'Style', 'Role'
    OptionA_Vi NVARCHAR(200) NOT NULL,
    OptionA_En NVARCHAR(200) NOT NULL,
    OptionA_Icon NVARCHAR(50) NULL DEFAULT '🛡️',
    OptionB_Vi NVARCHAR(200) NOT NULL,
    OptionB_En NVARCHAR(200) NOT NULL,
    OptionB_Icon NVARCHAR(50) NULL DEFAULT '👑',
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
GO

-- ============================================================================
-- 5. BẢNG CÂU TRẢ LỜI PHÁ BĂNG (IceBreakerAnswers)
-- ============================================================================
CREATE TABLE IceBreakerAnswers (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    QuestionId INT NOT NULL,
    User1Id NVARCHAR(450) NOT NULL,
    User2Id NVARCHAR(450) NOT NULL,
    User1Choice NVARCHAR(10) NULL, -- 'OptionA' hoặc 'OptionB'
    User2Choice NVARCHAR(10) NULL,
    IsMatched BIT NOT NULL DEFAULT 0,
    AnsweredAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY (QuestionId) REFERENCES IceBreakerQuestions(Id),
    FOREIGN KEY (User1Id) REFERENCES Users(Id),
    FOREIGN KEY (User2Id) REFERENCES Users(Id)
);
GO

-- ============================================================================
-- 6. BẢNG TIN NHẮN PHÒNG CHAT (ChatMessages)
-- ============================================================================
CREATE TABLE ChatMessages (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SenderId NVARCHAR(450) NOT NULL,
    ReceiverId NVARCHAR(450) NULL, -- NULL nếu gửi trong Lobby chung
    LobbyId INT NULL,             -- NULL nếu là Chat 1-1
    Content NVARCHAR(MAX) NOT NULL,
    IsAiSuggested BIT NOT NULL DEFAULT 0,
    SentAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY (SenderId) REFERENCES Users(Id),
    FOREIGN KEY (ReceiverId) REFERENCES Users(Id),
    FOREIGN KEY (LobbyId) REFERENCES Lobbies(Id) ON DELETE SET NULL
);
GO

-- ============================================================================
-- 7. BẢNG BÁO CÁO VI PHẠM (UserReports)
-- ============================================================================
CREATE TABLE UserReports (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ReportedUserId NVARCHAR(450) NOT NULL,
    ReporterUserId NVARCHAR(450) NOT NULL,
    Reason NVARCHAR(500) NOT NULL,
    Severity NVARCHAR(20) NOT NULL DEFAULT 'Medium', -- 'Low', 'Medium', 'High'
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',   -- 'Pending', 'Resolved', 'Dismissed'
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY (ReportedUserId) REFERENCES Users(Id),
    FOREIGN KEY (ReporterUserId) REFERENCES Users(Id)
);
GO

-- ============================================================================
-- 8. BẢNG DANH MỤC NHIỆM VỤ (Quests)
-- ============================================================================
CREATE TABLE Quests (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TitleVi NVARCHAR(200) NOT NULL,
    TitleEn NVARCHAR(200) NOT NULL,
    DescVi NVARCHAR(500) NOT NULL,
    DescEn NVARCHAR(500) NOT NULL,
    QuestType NVARCHAR(20) NOT NULL DEFAULT 'Daily', -- 'Daily', 'Weekly', 'Seasonal'
    TargetCount INT NOT NULL DEFAULT 1,
    RewardCoins INT NOT NULL DEFAULT 10,
    RewardExp INT NOT NULL DEFAULT 25,
    IsActive BIT NOT NULL DEFAULT 1
);
GO

-- ============================================================================
-- 9. BẢNG NHIỆM VỤ NGƯỜI DÙNG (UserQuests)
-- ============================================================================
CREATE TABLE UserQuests (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId NVARCHAR(450) NOT NULL,
    QuestId INT NOT NULL,
    ProgressCount INT NOT NULL DEFAULT 0,
    IsCompleted BIT NOT NULL DEFAULT 0,
    IsClaimed BIT NOT NULL DEFAULT 0,
    ClaimedAt DATETIME2 NULL,
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (QuestId) REFERENCES Quests(Id) ON DELETE CASCADE
);
GO

-- ============================================================================
-- 10. BẢNG GÓI DỊCH VỤ VIP PASS (VipPlans)
-- ============================================================================
CREATE TABLE VipPlans (
    PlanId NVARCHAR(50) NOT NULL PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    PriceNum INT NOT NULL,
    PriceText NVARCHAR(50) NOT NULL,
    Period NVARCHAR(20) NOT NULL DEFAULT '/tháng',
    AiTokenQuota INT NOT NULL DEFAULT 50000,
    Badge NVARCHAR(50) NULL,
    IsPopular BIT NOT NULL DEFAULT 0
);
GO

-- ============================================================================
-- 11. BẢNG GIAO DỊCH THANH TOÁN (Orders)
-- ============================================================================
CREATE TABLE Orders (
    OrderId NVARCHAR(100) NOT NULL PRIMARY KEY,
    OrderCode BIGINT NOT NULL UNIQUE,
    UserId NVARCHAR(450) NOT NULL,
    PlanId NVARCHAR(50) NOT NULL,
    Amount INT NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'PAID', 'CANCELLED', 'FAILED'
    PaymentMethod NVARCHAR(50) NOT NULL DEFAULT 'VietQR_PayOS',
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id),
    FOREIGN KEY (PlanId) REFERENCES VipPlans(PlanId)
);
GO

-- ============================================================================
-- DỮ LIỆU MẪU KHỞI TẠO (SEED DATA)
-- ============================================================================

-- Seed Users
INSERT INTO Users (Id, Name, Email, Age, Mbti, Game, Lane, Purpose, Coins, Exp, Level, IsVip, Role) VALUES
('usr-001', N'Lưu Phước Nhật Tú', 'tu.lpn@blush.vn', 20, 'INFJ', N'Liên Quân Mobile', N'Đường Giữa', N'Hội Tấu Hài', 340, 1250, 12, 1, 'Admin'),
('usr-002', N'Minh Thùy Gamer', 'thuy.minh@blush.vn', 19, 'ENFP', N'Valorant', N'Khởi Tranh', N'Chúa Tryhard', 150, 800, 8, 0, 'User'),
('usr-003', N'Hùng Moderator', 'hung.mod@blush.vn', 22, 'ISTJ', N'LMHT', N'Rừng', N'Thợ Săn Sự Kiện', 500, 2100, 20, 1, 'Staff');

-- Seed UserProfiles
INSERT INTO UserProfiles (UserId, Bio, Lifestyle, Hobbies, OverthinkAnswer, SundayAnswer, BadgesJson) VALUES
('usr-001', N'Mê game tấu hài & ca hát voice chat', N'Chill ban đêm', N'Gaming, Music, Coffee', N'Trận quan trọng mà team feed', N'Ngủ tới 12h rồi leo rank', N'["🎤 Top 1 Tấu Hài", "👑 Local MVP"]'),
('usr-002', N'Chúa Tryhard Valorant aim ngắm đầu', N'Tập trung cao độ', N'FPS, Esports', N'Bị hụt chuỗi 5 trận thắng', N'Xem giải đấu VCT', N'["🎯 Xạ Thủ Vàng"]');

-- Seed Lobbies
INSERT INTO Lobbies (Title, Game, Purpose, Description, MaxPlayers, CurrentOnline, IsVipOnly) VALUES
(N'Sảnh Tấu Hài Liên Quân #1', N'Liên Quân Mobile', N'Hội Tấu Hài', N'Vào voice chat ca hát giải trí', 5, 4, 0),
(N'Tryhard Rank Cao Thủ Valorant', N'Valorant', N'Chúa Tryhard', N'Cần Duelist nghiêm túc mic rõ', 5, 3, 0),
(N me'Sảnh Pro-Player Mentors', N'LMHT', N'Chúa Tryhard', N'Phòng kín có Cao Thủ Coach 1-1', 5, 2, 1);

-- Seed Quests
INSERT INTO Quests (TitleVi, TitleEn, DescVi, DescEn, QuestType, TargetCount, RewardCoins, RewardExp) VALUES
(N'Ghép đội 1 lần', 'Match 1 time', N'Sử dụng AI Matching để tìm đồng đội', 'Use AI Matching to find teammates', 'Daily', 1, 10, 25),
(N'Đăng 1 bài trên Feed', 'Post on Feed', N'Chia sẻ chiến tích hoặc chiến thuật', 'Share highlights or tactics', 'Daily', 1, 15, 30),
(N'Đạt chuỗi 3 trận thắng', '3 Win Streak', N'Cùng đồng đội ghép sảnh thắng liên tiếp 3 trận', 'Win 3 matches in a row with lobby team', 'Weekly', 3, 100, 250);

-- Seed VipPlans
INSERT INTO VipPlans (PlanId, Name, PriceNum, PriceText, Period, AiTokenQuota, Badge, IsPopular) VALUES
('month_basic', 'BLUSH Pass', 29000, '29K', '/tháng', 50000, NULL, 0),
('month_pro', 'BLUSH Pass Pro', 49000, '49K', '/tháng', 150000, N'PHỔ BIẾN NHẤT 🔥', 1);

PRINT N'✅ Khởi tạo CSDL BlushDb thành công!';
GO
