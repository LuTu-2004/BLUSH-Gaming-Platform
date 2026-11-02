-- ============================================================================
-- MIGRATION 021: Sửa giới thiệu tài khoản demo Khánh Linh cho khớp game đã khai
-- Chạy sau 020. Chỉ đổi đúng 1 dòng demo, chạy nhiều lần cũng không sao.
--   Linh chơi Liên Quân (Trợ thủ, leo rank) + Valorant (Sentinel, chơi vui), bản cũ lại ghi "Mid/AD".
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

UPDATE UserProfiles
SET Bio = N'Main Trợ thủ Liên Quân, đang leo Cao Thủ. Tối rảnh làm vài ván Valorant cho vui, mic rõ, không toxic.'
WHERE UserId = 'a0000000-0000-0000-0000-000000000001' AND Bio = N'Tìm đồng đội Mid/AD leo rank Cao Thủ, mic rõ, không toxic.';
GO

PRINT N'✅ Migration 021 (giới thiệu demo) xong!';
GO
