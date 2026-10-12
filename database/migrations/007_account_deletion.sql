-- ============================================================================
-- MIGRATION 007: Người dùng tự xóa tài khoản (Google Play bắt buộc)
-- Chạy sau 006. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- Xóa tài khoản = xóa hồ sơ, chat, sở thích...; dòng Users còn lại chỉ có Id (email thay bằng địa chỉ giả)
-- để giữ lịch sử thanh toán (kế toán) và báo cáo vi phạm (kiểm duyệt).
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thời điểm xóa
IF COL_LENGTH('Users', 'DeletedAt') IS NULL
    ALTER TABLE Users ADD DeletedAt DATETIME2 NULL;
GO

-- 2. Thêm trạng thái 'Deleted': bỏ CHECK cũ (tên do SQL Server tự đặt) rồi tạo CHECK có tên
DECLARE @old SYSNAME = (
    SELECT TOP 1 cc.name FROM sys.check_constraints cc
    WHERE cc.parent_object_id = OBJECT_ID('Users') AND cc.definition LIKE '%Banned%' AND cc.name <> 'CK_Users_Status');
IF @old IS NOT NULL EXEC('ALTER TABLE Users DROP CONSTRAINT [' + @old + ']');
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Users_Status')
    ALTER TABLE Users ADD CONSTRAINT CK_Users_Status CHECK (Status IN ('Active', 'Suspended', 'Banned', 'Deleted'));
GO

PRINT N'✅ Migration 007 (xóa tài khoản) xong!';
GO
