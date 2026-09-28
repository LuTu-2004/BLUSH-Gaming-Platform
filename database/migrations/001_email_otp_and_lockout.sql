-- ============================================================================
-- MIGRATION 001: Mã OTP qua email + chống dò mật khẩu
-- Dành cho máy ĐÃ tạo BlushDb bằng script_database.sql v2 (trước ngày 28/09/2026).
-- Chỉ THÊM cột/bảng mới, KHÔNG xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- (Máy tạo DB mới từ script_database.sql thì đã có sẵn, không cần chạy file này.)
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('Users', 'FailedLoginCount') IS NULL
    ALTER TABLE Users ADD FailedLoginCount INT NOT NULL CONSTRAINT DF_Users_FailedLoginCount DEFAULT 0;
GO
IF COL_LENGTH('Users', 'LockoutEndAt') IS NULL
    ALTER TABLE Users ADD LockoutEndAt DATETIME2 NULL;
GO

IF OBJECT_ID('EmailOtps') IS NULL
BEGIN
    CREATE TABLE EmailOtps (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
        Purpose VARCHAR(20) NOT NULL CHECK (Purpose IN ('VerifyEmail', 'ResetPassword')),
        CodeHash VARCHAR(100) NOT NULL,
        Attempts INT NOT NULL DEFAULT 0,
        ExpiresAt DATETIME2 NOT NULL,
        ConsumedAt DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_EmailOtps_User_Purpose ON EmailOtps(UserId, Purpose, CreatedAt);
END
GO

PRINT N'✅ Migration 001 (EmailOtps + Lockout) xong!';
GO
