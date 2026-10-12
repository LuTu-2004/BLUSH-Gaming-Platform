-- ============================================================================
-- MIGRATION 015: AI hỗ trợ kiểm duyệt
-- Chạy sau 014. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
--   Reports.AiScore / AiSummary: AI chấm mức vi phạm 0-100 -> báo cáo nặng lên đầu danh sách Staff
--   Reports.ReporterId NULL = báo cáo do AI tạo khi tạm ẩn bài viết / bình luận
--   Posts.HeldAt / PostComments.HeldAt: AI tạm ẩn chờ Staff duyệt (AI KHÔNG tự khóa tài khoản)
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

ALTER TABLE Reports ALTER COLUMN ReporterId UNIQUEIDENTIFIER NULL;
IF COL_LENGTH('Reports', 'AiScore') IS NULL
    ALTER TABLE Reports ADD AiScore SMALLINT NULL CONSTRAINT CK_Reports_AiScore CHECK (AiScore BETWEEN 0 AND 100);
IF COL_LENGTH('Reports', 'AiSummary') IS NULL
    ALTER TABLE Reports ADD AiSummary NVARCHAR(300) NULL;
IF COL_LENGTH('Reports', 'PostId') IS NULL
    ALTER TABLE Reports ADD PostId UNIQUEIDENTIFIER NULL CONSTRAINT FK_Reports_Post FOREIGN KEY REFERENCES Posts(Id);
IF COL_LENGTH('Reports', 'CommentId') IS NULL
    ALTER TABLE Reports ADD CommentId UNIQUEIDENTIFIER NULL CONSTRAINT FK_Reports_Comment FOREIGN KEY REFERENCES PostComments(Id);

IF COL_LENGTH('Posts', 'HeldAt') IS NULL
    ALTER TABLE Posts ADD HeldAt DATETIME2 NULL;
IF COL_LENGTH('PostComments', 'HeldAt') IS NULL
    ALTER TABLE PostComments ADD HeldAt DATETIME2 NULL;
GO

PRINT N'✅ Migration 015 (AI hỗ trợ kiểm duyệt) xong!';
GO
