-- ============================================================================
-- MIGRATION 022: Rương thưởng khi hoàn thành hết nhiệm vụ ngày (+50 Coins, +100 EXP, mỗi ngày 1 lần)
-- Chạy sau 021. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
--   Mức thưởng nằm ở backend/Services/Implementations/QuestService.cs (ChestCoins, ChestExp).
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('Users', 'LastDailyChestDate') IS NULL
    ALTER TABLE Users ADD LastDailyChestDate DATE NULL; -- ngày mở rương gần nhất (giờ Việt Nam)
GO

PRINT N'✅ Migration 022 (rương nhiệm vụ ngày) xong!';
GO
