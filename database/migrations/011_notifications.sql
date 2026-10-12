-- ============================================================================
-- MIGRATION 011: Thông báo trong app + đếm tin nhắn chưa đọc
-- Chạy sau 010. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thông báo (thả tim, bình luận, báo cáo đã xử lý, cảnh báo, nhiệm vụ, VIP...)
--    Link: nơi mở khi bấm, VD 'zone:2', 'chat:<userId>', 'vip', 'quests'
IF OBJECT_ID('Notifications') IS NULL
BEGIN
    CREATE TABLE Notifications (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
        Type VARCHAR(30) NOT NULL,
        Title NVARCHAR(120) NOT NULL,
        Body NVARCHAR(300) NULL,
        Link VARCHAR(100) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ReadAt DATETIME2 NULL                   -- NULL = chưa đọc
    );
    CREATE INDEX IX_Notifications_User_CreatedAt ON Notifications(UserId, CreatedAt);
END
GO

-- 2. Lần cuối mỗi người đọc phòng chat -> tin của người kia gửi sau mốc này là chưa đọc
IF COL_LENGTH('ChatRooms', 'User1LastReadAt') IS NULL
    ALTER TABLE ChatRooms ADD User1LastReadAt DATETIME2 NULL;
IF COL_LENGTH('ChatRooms', 'User2LastReadAt') IS NULL
    ALTER TABLE ChatRooms ADD User2LastReadAt DATETIME2 NULL;
GO

PRINT N'✅ Migration 011 (thông báo + tin chưa đọc) xong!';
GO
