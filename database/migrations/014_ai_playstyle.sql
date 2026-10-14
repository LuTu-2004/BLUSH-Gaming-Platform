-- ============================================================================
-- MIGRATION 014: Phong cách chơi do AI đọc từ phần tự viết (giới thiệu + muốn đồng đội như thế nào)
-- Chạy sau 013. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- 3 chỉ số -2..2 (NULL = chưa phân tích / không viết gì): ghép đội so khoảng cách giữa 2 người.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('UserProfiles', 'PlayCompetitive') IS NULL
    ALTER TABLE UserProfiles ADD PlayCompetitive SMALLINT NULL CONSTRAINT CK_UserProfiles_PlayCompetitive CHECK (PlayCompetitive BETWEEN -2 AND 2); -- -2 chill .. 2 tryhard
IF COL_LENGTH('UserProfiles', 'PlaySocial') IS NULL
    ALTER TABLE UserProfiles ADD PlaySocial SMALLINT NULL CONSTRAINT CK_UserProfiles_PlaySocial CHECK (PlaySocial BETWEEN -2 AND 2);                  -- -2 im lặng .. 2 thích nói chuyện
IF COL_LENGTH('UserProfiles', 'PlayHumor') IS NULL
    ALTER TABLE UserProfiles ADD PlayHumor SMALLINT NULL CONSTRAINT CK_UserProfiles_PlayHumor CHECK (PlayHumor BETWEEN -2 AND 2);                     -- -2 nghiêm túc .. 2 mê tấu hài
-- Hash của đoạn văn đã phân tích: văn bản không đổi thì không gọi AI lại
IF COL_LENGTH('UserProfiles', 'PlaystyleHash') IS NULL
    ALTER TABLE UserProfiles ADD PlaystyleHash VARCHAR(64) NULL;
GO

PRINT N'✅ Migration 014 (phong cách chơi bằng AI) xong!';
GO
