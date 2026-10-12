-- ============================================================================
-- MIGRATION 013: Nhật ký trận đấu (đồng đội xác nhận) + rank tự khai
-- Chạy sau 012. Chỉ THÊM / sửa mô tả, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- App không đọc được kết quả từ game thật (Liên Quân không có API) -> người chơi tự ghi, ĐỒNG ĐỘI xác nhận mới tính.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Trận đã chơi cùng 1 đồng đội BLUSH (2 người cùng phe)
IF OBJECT_ID('Matches') IS NULL
BEGIN
    CREATE TABLE Matches (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        ReporterId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),   -- người ghi
        TeammateId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),   -- người xác nhận
        GameId INT NOT NULL FOREIGN KEY REFERENCES Games(Id),
        Result VARCHAR(10) NOT NULL CONSTRAINT CK_Matches_Result CHECK (Result IN ('Win', 'Loss')),
        Status VARCHAR(20) NOT NULL DEFAULT 'Pending' CONSTRAINT CK_Matches_Status CHECK (Status IN ('Pending', 'Confirmed', 'Rejected')),
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ConfirmedAt DATETIME2 NULL,
        CONSTRAINT CK_Matches_NotSelf CHECK (ReporterId <> TeammateId)
    );
    CREATE INDEX IX_Matches_Reporter ON Matches(ReporterId, CreatedAt);
    CREATE INDEX IX_Matches_Teammate ON Matches(TeammateId, CreatedAt);
END
GO

-- 2. Rank tự khai cho từng game (danh sách rank theo game ở backend/Services/GameCatalog.cs)
IF COL_LENGTH('UserGameProfiles', 'Rank') IS NULL
    ALTER TABLE UserGameProfiles ADD [Rank] NVARCHAR(50) NULL;
GO

-- 3. Mô tả nhiệm vụ đúng với cách tính
UPDATE Quests SET DescVI = N'Ghi 3 trận chơi cùng đồng đội BLUSH (đồng đội xác nhận)' WHERE Code = 'daily_play_team';
UPDATE Quests SET DescVI = N'Thắng liên tiếp 3 trận cùng đồng đội BLUSH (đã xác nhận)' WHERE Code = 'weekly_win_streak';
UPDATE Quests SET DescVI = N'Chơi 5 trận (đã xác nhận) cùng người chơi Level 5 trở xuống' WHERE Code = 'weekly_help_newbie';
UPDATE Quests SET DescVI = N'Khai rank Cao Thủ (hoặc tương đương) cho 1 game trong hồ sơ' WHERE Code = 'season_master_rank';
GO

PRINT N'✅ Migration 013 (nhật ký trận đấu + rank) xong!';
GO
