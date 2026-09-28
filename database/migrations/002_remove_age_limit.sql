-- ============================================================================
-- MIGRATION 002: Bỏ giới hạn độ tuổi 18+ (xóa ràng buộc CK_UserProfiles_Age18)
-- Chạy sau 001. Không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO

IF OBJECT_ID('CK_UserProfiles_Age18', 'C') IS NOT NULL
    ALTER TABLE UserProfiles DROP CONSTRAINT CK_UserProfiles_Age18;
GO

PRINT N'✅ Migration 002 (bỏ giới hạn 18+) xong!';
GO
