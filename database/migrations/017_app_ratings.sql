-- ============================================================================
-- MIGRATION 017: Đánh giá app BLUSH (1-5 sao + góp ý)
-- Chạy sau 016. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
--   AppRatings: mỗi người 1 đánh giá (UserId không trùng). Đánh giá lại = sửa dòng cũ.
--   Admin xem điểm trung bình + lịch sử đánh giá ở trang quản trị.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('AppRatings', 'U') IS NULL
BEGIN
    CREATE TABLE AppRatings (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        UserId UNIQUEIDENTIFIER NOT NULL UNIQUE FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
        Stars TINYINT NOT NULL CHECK (Stars BETWEEN 1 AND 5),
        Comment NVARCHAR(1000) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_AppRatings_UpdatedAt ON AppRatings(UpdatedAt);
END
GO

PRINT N'✅ Migration 017 (đánh giá app) xong!';
GO
