-- ============================================================================
-- MIGRATION 018: Người dùng biết BLUSH qua đâu (Google, Facebook, TikTok...)
-- Chạy sau 017. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
--   App hỏi 1 lần sau khi làm khảo sát (người cũ: lần mở app kế tiếp). Bỏ qua = để NULL.
--   Admin xem tỉ lệ từng kênh ở box "Nguồn người dùng" trong Tổng quan.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('UserProfiles', 'AcquisitionSource') IS NULL
    ALTER TABLE UserProfiles ADD AcquisitionSource VARCHAR(20) NULL
        CONSTRAINT CK_UserProfiles_AcquisitionSource CHECK (AcquisitionSource IN ('google', 'facebook', 'tiktok', 'youtube', 'friend', 'other'));
IF COL_LENGTH('UserProfiles', 'AcquisitionSourceAt') IS NULL
    ALTER TABLE UserProfiles ADD AcquisitionSourceAt DATETIME2 NULL; -- lúc trả lời
GO

PRINT N'✅ Migration 018 (nguồn người dùng) xong!';
GO
