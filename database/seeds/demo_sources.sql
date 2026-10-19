-- ============================================================================
-- DỮ LIỆU DEMO (TÙY CHỌN): nguồn người dùng mẫu để box "Nguồn người dùng" trong Tổng quan của Admin có số liệu.
-- Chạy sau migration 018. KHÔNG chạy trên DB thật có khách hàng.
--
-- - Chỉ đặt nguồn cho 8 người chơi mẫu *@demo.blush.vn (migration 004). Chạy lại nhiều lần cũng không sao.
-- - Xóa: UPDATE UserProfiles SET AcquisitionSource = NULL, AcquisitionSourceAt = NULL
--        WHERE UserId IN (SELECT Id FROM Users WHERE Email LIKE '%@demo.blush.vn')
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DECLARE @demo TABLE (Email VARCHAR(100), Source VARCHAR(20));
INSERT INTO @demo VALUES
('linh@demo.blush.vn',  'facebook'),
('dung@demo.blush.vn',  'facebook'),
('khoa@demo.blush.vn',  'tiktok'),
('thuy@demo.blush.vn',  'friend'),
('nam@demo.blush.vn',   'google'),
('yen@demo.blush.vn',   'facebook'),
('vy@demo.blush.vn',    'tiktok'),
('dungh@demo.blush.vn', 'youtube');

UPDATE p SET p.AcquisitionSource = d.Source, p.AcquisitionSourceAt = SYSUTCDATETIME()
FROM UserProfiles p
JOIN Users u ON u.Id = p.UserId
JOIN @demo d ON d.Email = u.Email;

PRINT N'✅ Đã đặt nguồn cho ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' người chơi demo.';
GO
