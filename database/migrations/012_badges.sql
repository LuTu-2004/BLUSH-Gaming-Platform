-- ============================================================================
-- MIGRATION 012: Huy hiệu có điều kiện rõ ràng, backend tự trao (Services/Implementations/BadgeService.cs)
-- Chạy sau 011. Chỉ THÊM / sửa mô tả, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Mô tả = điều kiện nhận (khớp luật trong BadgeService)
UPDATE Badges SET Description = N'Đứng đầu EXP trong 1 Zone Giải trí (từ 3 thành viên)' WHERE Code = 'top1_fun';
UPDATE Badges SET Description = N'Top 3 EXP trong khu vực của bạn (TP.HCM / Hà Nội)' WHERE Code = 'local_mvp';
UPDATE Badges SET Description = N'Hoàn thành 30 trận Tryhard cùng đồng đội BLUSH (đã xác nhận)' WHERE Code = 'tryhard_king';
GO

-- 2. Huy hiệu mới, tính từ hoạt động có sẵn
MERGE Badges AS t
USING (VALUES
    ('first_connection', N'Kết nối đầu tiên', 'First connection', N'🤝', N'Có cuộc trò chuyện mà cả hai bên đều đã nhắn'),
    ('zone_star',        N'Ngôi sao Zone',    'Zone star',        N'🌟', N'Có bài đăng được từ 10 tim'),
    ('friendly',         N'Hòa đồng',         'Friendly',         N'💬', N'Viết 20 bình luận trong các Zone'),
    ('hard_worker',      N'Chăm chỉ',         'Hard worker',      N'✅', N'Hoàn thành 10 nhiệm vụ'),
    ('supporter',        N'Người ủng hộ',     'Supporter',        N'💜', N'Từng mua BLUSH Pass')
) AS s (Code, NameVI, NameEN, Icon, Description)
ON t.Code = s.Code
WHEN NOT MATCHED THEN INSERT (Code, NameVI, NameEN, Icon, Description) VALUES (s.Code, s.NameVI, s.NameEN, s.Icon, s.Description);
GO

PRINT N'✅ Migration 012 (huy hiệu) xong!';
GO
