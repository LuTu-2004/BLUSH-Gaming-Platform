-- ============================================================================
-- MIGRATION 004: Onboarding sau đăng ký + dữ liệu ghép đội (matching)
-- Chạy sau 003. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thông tin thêm trong hồ sơ
--    OnboardingCompletedAt NULL = chưa làm khảo sát -> app bắt làm trước khi vào trang chủ
IF COL_LENGTH('UserProfiles', 'OnboardingCompletedAt') IS NULL
    ALTER TABLE UserProfiles ADD OnboardingCompletedAt DATETIME2 NULL;
IF COL_LENGTH('UserProfiles', 'UsesMic') IS NULL
    ALTER TABLE UserProfiles ADD UsesMic BIT NULL;                -- NULL = tùy trận
-- Người dùng tự viết "muốn đồng đội như thế nào" -> để dành cho AI đọc (rule-based không dùng)
IF COL_LENGTH('UserProfiles', 'TeammateWish') IS NULL
    ALTER TABLE UserProfiles ADD TeammateWish NVARCHAR(300) NULL;
GO

-- 2. Khung giờ hay chơi (1 người chọn nhiều khung)
IF OBJECT_ID('UserPlayTimes') IS NULL
BEGIN
    CREATE TABLE UserPlayTimes (
        UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id) ON DELETE CASCADE,
        Slot VARCHAR(20) NOT NULL
            CONSTRAINT CK_UserPlayTimes_Slot CHECK (Slot IN ('Morning', 'Afternoon', 'Evening', 'LateNight', 'Weekend')),
        PRIMARY KEY (UserId, Slot)
    );
END
GO

-- 3. Người chơi mẫu để màn "Đồng đội" có người ghép khi demo. Mật khẩu đều là '123456'.
DECLARE @hash VARCHAR(255) = '$2a$11$11bxfSM1RRJrN.Sx0udTGeHCK7P31lcH6ASAwi09Wy2bHUn5OkMOC';

DECLARE @demo TABLE (
    Id UNIQUEIDENTIFIER, Email VARCHAR(255), DisplayName NVARCHAR(50), Dob DATE, Mbti CHAR(4),
    Bio NVARCHAR(500), Region VARCHAR(10), Avatar NVARCHAR(16), UsesMic BIT, Exp INT
);
INSERT INTO @demo VALUES
('a0000000-0000-0000-0000-000000000001', 'linh@demo.blush.vn',  N'Khánh Linh', '2005-04-12', 'ENFP', N'Tìm đồng đội Mid/AD leo rank Cao Thủ, mic rõ, không toxic.', 'HCM', N'🌸', 1, 2300),
('a0000000-0000-0000-0000-000000000002', 'dung@demo.blush.vn',  N'Thùy Dung',  '2004-09-02', 'ENFP', N'Chuyên solo Mid, đang leo Kim Cương.',                       'HN',  N'👑', 1, 1800),
('a0000000-0000-0000-0000-000000000003', 'thuy@demo.blush.vn',  N'Minh Thùy',  '2006-02-20', 'INTP', N'Cày sảnh giải trí sau giờ học, thích voice chat ca hát.',   'HCM', N'⚔️', 1, 900),
('a0000000-0000-0000-0000-000000000004', 'nam@demo.blush.vn',   N'Bảo Nam',    '2005-11-30', 'ESTP', N'Săn Booyah mỗi tối, cần đồng đội bo sát.',                   'HCM', N'💥', 1, 1500),
('a0000000-0000-0000-0000-000000000005', 'yen@demo.blush.vn',   N'Hoàng Yến',  '2007-06-15', 'ESFP', N'Chơi cho vui là chính, cười banh sảnh.',                     'HN',  N'🔥', 0, 600),
('a0000000-0000-0000-0000-000000000006', 'dungh@demo.blush.vn', N'Hùng Dũng',  '2003-01-08', 'ISTJ', N'Leo rank nghiêm túc, chơi theo meta.',                       'HN',  N'🎯', NULL, 3100),
('a0000000-0000-0000-0000-000000000007', 'vy@demo.blush.vn',    N'Tường Vy',   '2006-08-24', 'INFP', N'Đêm khuya mới online, thích Co-op nhẹ nhàng.',               'HCM', N'🌙', 0, 750),
('a0000000-0000-0000-0000-000000000008', 'khoa@demo.blush.vn',  N'Đăng Khoa',  '2004-03-03', 'ENTJ', N'Shotcaller Valorant, cần team 5 người tập luyện.',           'HCM', N'🛡️', 1, 2700);

INSERT INTO Users (Id, RoleId, Email, EmailConfirmed, PasswordHash, Exp, Coins)
SELECT d.Id, 1, d.Email, 1, @hash, d.Exp, 100
FROM @demo d WHERE NOT EXISTS (SELECT 1 FROM Users u WHERE u.Id = d.Id);

INSERT INTO UserProfiles (UserId, DisplayName, DateOfBirth, MBTI, Bio, Region, AvatarEmoji, UsesMic, OnboardingCompletedAt)
SELECT d.Id, d.DisplayName, d.Dob, d.Mbti, d.Bio, d.Region, d.Avatar, d.UsesMic, SYSUTCDATETIME()
FROM @demo d WHERE NOT EXISTS (SELECT 1 FROM UserProfiles p WHERE p.UserId = d.Id);

-- Game từng người chơi (tra Id theo tên game để không phụ thuộc thứ tự IDENTITY)
DECLARE @games TABLE (UserId UNIQUEIDENTIFIER, GameName NVARCHAR(100), Position NVARCHAR(50), Purpose VARCHAR(20));
INSERT INTO @games VALUES
('a0000000-0000-0000-0000-000000000001', N'Liên Quân Mobile',   N'Trợ thủ',     'Tryhard'),
('a0000000-0000-0000-0000-000000000001', N'Valorant',           N'Sentinel',    'Fun'),
('a0000000-0000-0000-0000-000000000002', N'LMHT',               N'Đường giữa',  'Tryhard'),
('a0000000-0000-0000-0000-000000000003', N'Valorant',           N'Initiator',   'Fun'),
('a0000000-0000-0000-0000-000000000003', N'Liên Quân Mobile',   N'Đường giữa',  'Fun'),
('a0000000-0000-0000-0000-000000000004', N'PUBG Mobile',        N'Xạ thủ',      'Tryhard'),
('a0000000-0000-0000-0000-000000000004', N'Free Fire',          N'Tiên phong',  'Fun'),
('a0000000-0000-0000-0000-000000000005', N'Liên Quân Mobile',   N'Xạ thủ',      'Fun'),
('a0000000-0000-0000-0000-000000000005', N'Free Fire',          N'Hỗ trợ',      'Fun'),
('a0000000-0000-0000-0000-000000000006', N'Đấu Trường Chân Lý', NULL,           'Tryhard'),
('a0000000-0000-0000-0000-000000000006', N'LMHT',               N'Đi rừng',     'Tryhard'),
('a0000000-0000-0000-0000-000000000007', N'Đấu Trường Chân Lý', NULL,           'Fun'),
('a0000000-0000-0000-0000-000000000007', N'Liên Quân Mobile',   N'Trợ thủ',     'Fun'),
('a0000000-0000-0000-0000-000000000008', N'Valorant',           N'Controller',  'Tryhard');

INSERT INTO UserGameProfiles (UserId, GameId, PreferredPosition, Purpose)
SELECT x.UserId, g.Id, x.Position, x.Purpose
FROM @games x JOIN Games g ON g.GameName = x.GameName
WHERE NOT EXISTS (SELECT 1 FROM UserGameProfiles ug WHERE ug.UserId = x.UserId AND ug.GameId = g.Id);

DECLARE @times TABLE (UserId UNIQUEIDENTIFIER, Slot VARCHAR(20));
INSERT INTO @times VALUES
('a0000000-0000-0000-0000-000000000001', 'Evening'),   ('a0000000-0000-0000-0000-000000000001', 'Weekend'),
('a0000000-0000-0000-0000-000000000002', 'Afternoon'), ('a0000000-0000-0000-0000-000000000002', 'Evening'),
('a0000000-0000-0000-0000-000000000003', 'Evening'),   ('a0000000-0000-0000-0000-000000000003', 'LateNight'),
('a0000000-0000-0000-0000-000000000004', 'Evening'),
('a0000000-0000-0000-0000-000000000005', 'Afternoon'), ('a0000000-0000-0000-0000-000000000005', 'Weekend'),
('a0000000-0000-0000-0000-000000000006', 'Morning'),   ('a0000000-0000-0000-0000-000000000006', 'Weekend'),
('a0000000-0000-0000-0000-000000000007', 'LateNight'),
('a0000000-0000-0000-0000-000000000008', 'Evening'),   ('a0000000-0000-0000-0000-000000000008', 'Weekend');

INSERT INTO UserPlayTimes (UserId, Slot)
SELECT x.UserId, x.Slot FROM @times x
WHERE NOT EXISTS (SELECT 1 FROM UserPlayTimes t WHERE t.UserId = x.UserId AND t.Slot = x.Slot);

DECLARE @hobbies TABLE (UserId UNIQUEIDENTIFIER, Name NVARCHAR(50));
INSERT INTO @hobbies VALUES
('a0000000-0000-0000-0000-000000000001', N'Voice Chat'), ('a0000000-0000-0000-0000-000000000001', N'K-Pop'),
('a0000000-0000-0000-0000-000000000002', N'Tryhard'),    ('a0000000-0000-0000-0000-000000000002', N'Co-op'),
('a0000000-0000-0000-0000-000000000003', N'Anime'),      ('a0000000-0000-0000-0000-000000000003', N'Âm nhạc'),
('a0000000-0000-0000-0000-000000000004', N'Streaming'),  ('a0000000-0000-0000-0000-000000000004', N'Tryhard'),
('a0000000-0000-0000-0000-000000000005', N'Voice Chat'), ('a0000000-0000-0000-0000-000000000005', N'Âm nhạc'),
('a0000000-0000-0000-0000-000000000006', N'Tryhard'),
('a0000000-0000-0000-0000-000000000007', N'Anime'),      ('a0000000-0000-0000-0000-000000000007', N'Co-op'),
('a0000000-0000-0000-0000-000000000008', N'Streaming'),  ('a0000000-0000-0000-0000-000000000008', N'Voice Chat');

INSERT INTO UserHobbies (UserId, HobbyId)
SELECT x.UserId, h.Id
FROM @hobbies x JOIN Hobbies h ON h.Name = x.Name
WHERE NOT EXISTS (SELECT 1 FROM UserHobbies uh WHERE uh.UserId = x.UserId AND uh.HobbyId = h.Id);
GO

PRINT N'✅ Migration 004 (onboarding + ghép đội) xong!';
GO
