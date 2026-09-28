-- ============================================================================
-- MIGRATION 003: Xác thực 2 bước qua email + thiết bị tin cậy
-- Chạy sau 002. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Cột bật/tắt 2 bước
IF COL_LENGTH('Users', 'TwoFactorEnabled') IS NULL
    ALTER TABLE Users ADD TwoFactorEnabled BIT NOT NULL CONSTRAINT DF_Users_TwoFactorEnabled DEFAULT 0;
GO

-- 2. Cho EmailOtps.Purpose nhận thêm 'TwoFactorLogin' (mã đăng nhập) và 'EnableTwoFactor' (mã xác nhận khi bật).
--    Ràng buộc cũ có thể không đặt tên (SQL tự sinh tên) nên phải tìm tên rồi mới xóa được.
DECLARE @old SYSNAME, @sql NVARCHAR(400);
SELECT @old = cc.name
FROM sys.check_constraints cc
JOIN sys.columns c ON c.object_id = cc.parent_object_id AND c.column_id = cc.parent_column_id
WHERE cc.parent_object_id = OBJECT_ID('EmailOtps') AND c.name = 'Purpose'
  AND cc.definition NOT LIKE '%EnableTwoFactor%';
IF @old IS NOT NULL
BEGIN
    SET @sql = N'ALTER TABLE EmailOtps DROP CONSTRAINT ' + QUOTENAME(@old);
    EXEC sp_executesql @sql;
END
IF OBJECT_ID('CK_EmailOtps_Purpose', 'C') IS NULL
    ALTER TABLE EmailOtps ADD CONSTRAINT CK_EmailOtps_Purpose
        CHECK (Purpose IN ('VerifyEmail', 'ResetPassword', 'TwoFactorLogin', 'EnableTwoFactor'));
GO

-- 3. Bảng thiết bị tin cậy
IF OBJECT_ID('TrustedDevices') IS NULL
BEGIN
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
END
GO

PRINT N'✅ Migration 003 (xác thực 2 bước) xong!';
GO
