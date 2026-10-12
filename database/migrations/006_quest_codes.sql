-- ============================================================================
-- MIGRATION 006: Nhiệm vụ thật (API api/quest) - thêm cột Code cho Quests
-- Chạy sau 005. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- Backend dùng Code (không dùng Id) để biết hành động nào cộng tiến độ cho nhiệm vụ nào.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thêm cột Code (tạm cho NULL để điền giá trị cho các dòng có sẵn)
IF COL_LENGTH('Quests', 'Code') IS NULL
    ALTER TABLE Quests ADD Code VARCHAR(50) NULL;
GO

-- 2. Điền Code cho 8 nhiệm vụ mẫu (tìm theo TitleEN), nhiệm vụ Admin tự thêm thì đặt quest_<Id>
UPDATE Quests SET Code = CASE TitleEN
        WHEN 'Match 1 time' THEN 'daily_match'
        WHEN 'Post on Feed' THEN 'daily_feed_post'
        WHEN 'Like 5 posts' THEN 'daily_feed_like'
        WHEN 'Play 3 matches with BLUSH team' THEN 'daily_play_team'
        WHEN '3 Win Streak' THEN 'weekly_win_streak'
        WHEN 'Help 5 newbies' THEN 'weekly_help_newbie'
        WHEN 'Reach Master rank' THEN 'season_master_rank'
        WHEN '50 Feed interactions' THEN 'season_feed_interact'
        ELSE 'quest_' + CAST(Id AS VARCHAR(10))
    END
WHERE Code IS NULL;
GO

-- 3. Bắt buộc + không trùng
IF COLUMNPROPERTY(OBJECT_ID('Quests'), 'Code', 'AllowsNull') = 1
    ALTER TABLE Quests ALTER COLUMN Code VARCHAR(50) NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Quests_Code')
    ALTER TABLE Quests ADD CONSTRAINT UQ_Quests_Code UNIQUE (Code);
GO

PRINT N'✅ Migration 006 (mã nhiệm vụ) xong!';
GO
