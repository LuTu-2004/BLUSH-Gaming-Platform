-- ============================================================================
-- MIGRATION 016: Thông báo đẩy (Firebase Cloud Messaging)
-- Chạy sau 015. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
--   DeviceTokens: mã FCM của từng điện thoại đã đăng nhập -> backend gửi thông báo khi app đang tắt
--   1 điện thoại = 1 mã. Đăng nhập tài khoản khác trên cùng máy thì mã chuyển sang tài khoản mới.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('DeviceTokens', 'U') IS NULL
BEGIN
    CREATE TABLE DeviceTokens (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
        Token VARCHAR(512) NOT NULL UNIQUE,
        Platform VARCHAR(10) NOT NULL CHECK (Platform IN ('android', 'ios', 'web')),
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_DeviceTokens_UserId ON DeviceTokens(UserId);
END
GO

PRINT N'✅ Migration 016 (thông báo đẩy) xong!';
GO
