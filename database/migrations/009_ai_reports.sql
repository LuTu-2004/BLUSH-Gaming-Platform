-- ============================================================================
-- MIGRATION 009: Người dùng báo cáo câu trả lời AI không phù hợp
-- (chính sách Google Play với nội dung do AI tạo). Chạy sau 008. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('AiLogs', 'ReportedAt') IS NULL
    ALTER TABLE AiLogs ADD ReportedAt DATETIME2 NULL;        -- NULL = chưa ai báo cáo
IF COL_LENGTH('AiLogs', 'ReportReason') IS NULL
    ALTER TABLE AiLogs ADD ReportReason NVARCHAR(500) NULL;
GO

PRINT N'✅ Migration 009 (báo cáo câu trả lời AI) xong!';
GO
