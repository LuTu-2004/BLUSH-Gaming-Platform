-- ============================================================================
-- MIGRATION 020: Câu hỏi phong cách chơi trong khảo sát (vai trò, mức nói chuyện, kiểu nói chuyện)
-- Chạy sau 019. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
--   Không bắt buộc trả lời (NULL = chưa chọn). Ghép đội dùng cùng chỉ số AI ở mục "Phong cách chơi".
--   Mã khớp backend/Services/PlaystyleChoices.cs
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('UserProfiles', 'TeamRole') IS NULL
    ALTER TABLE UserProfiles ADD TeamRole VARCHAR(20) NULL
        CONSTRAINT CK_UserProfiles_TeamRole CHECK (TeamRole IN ('Shotcaller', 'Carry', 'Support', 'Flex'));
IF COL_LENGTH('UserProfiles', 'TalkLevel') IS NULL
    ALTER TABLE UserProfiles ADD TalkLevel VARCHAR(20) NULL
        CONSTRAINT CK_UserProfiles_TalkLevel CHECK (TalkLevel IN ('Quiet', 'Normal', 'Chatty'));
IF COL_LENGTH('UserProfiles', 'BanterLevel') IS NULL
    ALTER TABLE UserProfiles ADD BanterLevel VARCHAR(20) NULL
        CONSTRAINT CK_UserProfiles_BanterLevel CHECK (BanterLevel IN ('Gentle', 'Honest', 'Banter'));
GO

PRINT N'✅ Migration 020 (câu hỏi phong cách chơi) xong!';
GO
