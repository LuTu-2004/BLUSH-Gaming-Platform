-- ============================================================================
-- DỮ LIỆU DEMO (TÙY CHỌN): đánh giá app mẫu để box Đánh giá + trang Lịch sử đánh giá có số liệu khi demo.
-- Chạy sau migration 017. KHÔNG chạy trên DB thật có khách hàng.
--
-- - Chỉ thêm đánh giá cho 8 người chơi mẫu *@demo.blush.vn (migration 004), rải trong 20 ngày gần nhất.
-- - Chạy lại: xóa đánh giá của người chơi mẫu rồi tạo lại theo ngày hôm nay.
-- - Xóa hẳn: DELETE FROM AppRatings WHERE UserId IN (SELECT Id FROM Users WHERE Email LIKE '%@demo.blush.vn')
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DELETE FROM AppRatings WHERE UserId IN (SELECT Id FROM Users WHERE Email LIKE '%@demo.blush.vn');

-- Email, số sao, góp ý, cách đây bao nhiêu ngày
DECLARE @demo TABLE (Email VARCHAR(100), Stars TINYINT, Comment NVARCHAR(1000), DaysAgo INT);
INSERT INTO @demo VALUES
('linh@demo.blush.vn',  5, N'Ghép đội nhanh, gặp được team Valorant hợp gu. Rất thích phần AI gợi ý câu mở đầu!', 1),
('dung@demo.blush.vn',  5, NULL, 2),
('khoa@demo.blush.vn',  4, N'App ổn, mong có thêm Liên Minh Huyền Thoại bản Việt Nam.', 3),
('thuy@demo.blush.vn',  4, N'Giao diện đẹp, thỉnh thoảng thông báo đến hơi trễ.', 5),
('nam@demo.blush.vn',   3, N'Giờ tối đông người nhưng sáng thì ít ai để ghép.', 8),
('yen@demo.blush.vn',   5, N'Tìm được bạn chơi cùng giờ, không còn phải chơi một mình nữa.', 11),
('vy@demo.blush.vn',    2, N'Gói VIP hơi đắt so với sinh viên.', 14),
('dungh@demo.blush.vn', 4, NULL, 20);

INSERT INTO AppRatings (UserId, Stars, Comment, CreatedAt, UpdatedAt)
SELECT u.Id, d.Stars, d.Comment, DATEADD(DAY, -d.DaysAgo, SYSUTCDATETIME()), DATEADD(DAY, -d.DaysAgo, SYSUTCDATETIME())
FROM @demo d
JOIN Users u ON u.Email = d.Email;

PRINT N'✅ Đã tạo ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' đánh giá demo.';
GO
