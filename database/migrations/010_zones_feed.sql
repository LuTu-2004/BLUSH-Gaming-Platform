-- ============================================================================
-- MIGRATION 010: Zone (cộng đồng theo game + mục đích) và Feed (bài đăng, thả tim, bình luận)
-- Chạy sau 009. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thành viên Zone (tự xếp sau khảo sát theo game + mục đích, hoặc tự tham gia)
IF OBJECT_ID('UserZones') IS NULL
BEGIN
    CREATE TABLE UserZones (
        UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
        ZoneId INT NOT NULL FOREIGN KEY REFERENCES Zones(Id),
        JoinedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        PRIMARY KEY (UserId, ZoneId)
    );
END
GO

-- 2. Bài đăng trong Zone. IsRemoved = người đăng hoặc Staff đã gỡ (giữ lại để xử lý báo cáo)
IF OBJECT_ID('Posts') IS NULL
BEGIN
    CREATE TABLE Posts (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        ZoneId INT NOT NULL FOREIGN KEY REFERENCES Zones(Id),
        AuthorId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
        Content NVARCHAR(1000) NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        RemovedAt DATETIME2 NULL,
        RemovedBy UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES Users(Id)
    );
    CREATE INDEX IX_Posts_Zone_CreatedAt ON Posts(ZoneId, CreatedAt);
END
GO

IF OBJECT_ID('PostLikes') IS NULL
BEGIN
    CREATE TABLE PostLikes (
        PostId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Posts(Id) ON DELETE CASCADE,
        UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        PRIMARY KEY (PostId, UserId)
    );
END
GO

IF OBJECT_ID('PostComments') IS NULL
BEGIN
    CREATE TABLE PostComments (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        PostId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Posts(Id) ON DELETE CASCADE,
        AuthorId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
        Content NVARCHAR(500) NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        RemovedAt DATETIME2 NULL
    );
    CREATE INDEX IX_PostComments_Post ON PostComments(PostId, CreatedAt);
END
GO

-- 3. Zone kín: không có coach thật -> mô tả đúng với tính năng
UPDATE Zones SET ZoneName = N'Sảnh kín BLUSH Pass Pro', Description = N'Zone kín cho thành viên BLUSH Pass Pro: trao đổi chiến thuật leo rank'
WHERE IsVipOnly = 1 AND Description LIKE N'%Coach%';
GO

-- 4. Xếp người đã làm khảo sát vào Zone theo game + mục đích (người mới sẽ được xếp khi lưu khảo sát)
INSERT INTO UserZones (UserId, ZoneId)
SELECT DISTINCT g.UserId, z.Id
FROM UserGameProfiles g
JOIN Zones z ON z.GameId = g.GameId AND z.Purpose = g.Purpose AND z.IsVipOnly = 0
WHERE NOT EXISTS (SELECT 1 FROM UserZones uz WHERE uz.UserId = g.UserId AND uz.ZoneId = z.Id);
GO

PRINT N'✅ Migration 010 (Zone + Feed) xong!';
GO
