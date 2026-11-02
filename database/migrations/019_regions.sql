-- ============================================================================
-- MIGRATION 019: Mở rộng khu vực từ TP.HCM / Hà Nội ra 34 tỉnh/thành + "Nước ngoài"
-- Chạy sau 018. Chỉ BỎ ràng buộc cũ, không đổi dữ liệu (HCM/HN giữ nguyên mã). Chạy nhiều lần cũng không sao.
--   Danh sách mã tỉnh + miền nằm ở backend/Services/GameCatalog.cs, backend tự kiểm tra khi lưu khảo sát.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- CHECK (Region IN ('HCM', 'HN')) tạo không đặt tên -> tìm tên do SQL Server sinh ra rồi xóa
DECLARE @constraint SYSNAME = (
    SELECT cc.name FROM sys.check_constraints cc
    JOIN sys.columns c ON c.object_id = cc.parent_object_id AND c.column_id = cc.parent_column_id
    WHERE cc.parent_object_id = OBJECT_ID('UserProfiles') AND c.name = 'Region');
IF @constraint IS NOT NULL
    EXEC('ALTER TABLE UserProfiles DROP CONSTRAINT ' + @constraint);
GO

UPDATE Badges SET Description = N'Top 3 EXP trong tỉnh/thành của bạn' WHERE Code = 'local_mvp';
GO

PRINT N'✅ Migration 019 (34 tỉnh/thành) xong!';
GO
