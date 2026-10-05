-- ============================================================================
-- DỮ LIỆU DEMO (TÙY CHỌN): giao dịch mẫu 30 ngày gần nhất để Dashboard doanh thu có số liệu khi demo.
-- Chạy sau migration 005. KHÔNG chạy trên DB thật có khách hàng.
--
-- - Chỉ thêm giao dịch cho 8 người chơi mẫu *@demo.blush.vn (migration 004).
-- - Mọi dòng có GatewayTransactionId bắt đầu bằng 'SEED-' -> xóa bằng đoạn cuối file.
-- - Chỉ thêm vào bảng Transactions (không cấp VIP), nên số "VIP đang hoạt động" không đổi.
-- - Chạy lại: xóa dữ liệu demo cũ rồi tạo lại theo ngày hôm nay.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DELETE FROM Transactions WHERE GatewayTransactionId LIKE 'SEED-%';

DECLARE @users TABLE (N INT IDENTITY(0,1), UserId UNIQUEIDENTIFIER);
INSERT INTO @users (UserId) SELECT Id FROM Users WHERE Email LIKE '%@demo.blush.vn' ORDER BY Email;
DECLARE @userCount INT = (SELECT COUNT(*) FROM @users);
IF @userCount = 0
BEGIN
    PRINT N'⚠️ Chưa có người chơi mẫu, hãy chạy migration 004 trước.';
    RETURN;
END

DECLARE @basic INT = (SELECT Id FROM VipPackages WHERE PackageCode = 'month_basic');
DECLARE @pro INT = (SELECT Id FROM VipPackages WHERE PackageCode = 'month_pro');
DECLARE @quarter INT = (SELECT Id FROM VipPackages WHERE PackageCode = 'quarter_pro');

-- Mỗi ngày 0-4 giao dịch, ngày gần đây nhiều hơn (giống app đang tăng trưởng)
DECLARE @day INT = 29, @i INT, @perDay INT, @n INT = 0;
DECLARE @r INT, @pkg INT, @userId UNIQUEIDENTIFIER, @pick INT, @method VARCHAR(30), @status VARCHAR(20), @created DATETIME2, @amount DECIMAL(18,2);

WHILE @day >= 0
BEGIN
    SET @perDay = ABS(CHECKSUM(NEWID())) % (2 + (30 - @day) / 8);
    SET @i = 0;
    WHILE @i < @perDay
    BEGIN
        SET @r = ABS(CHECKSUM(NEWID())) % 100;
        SET @pkg = CASE WHEN @r < 40 THEN @basic WHEN @r < 85 THEN @pro ELSE @quarter END;
        SET @r = ABS(CHECKSUM(NEWID())) % 100;
        SET @method = CASE WHEN @r < 40 THEN 'MoMo' WHEN @r < 65 THEN 'VNPay' WHEN @r < 85 THEN 'VietQR' ELSE 'ZaloPay' END;
        SET @r = ABS(CHECKSUM(NEWID())) % 100;
        SET @status = CASE WHEN @r < 78 THEN 'Paid' WHEN @r < 88 THEN 'Cancelled' ELSE 'Failed' END;
        SET @created = DATEADD(MINUTE, -(ABS(CHECKSUM(NEWID())) % 900), DATEADD(DAY, -@day, SYSUTCDATETIME()));
        SET @amount = (SELECT Price FROM VipPackages WHERE Id = @pkg);
        SET @pick = ABS(CHECKSUM(NEWID())) % @userCount;
        SET @userId = (SELECT UserId FROM @users WHERE N = @pick);

        INSERT INTO Transactions (Id, OrderCode, UserId, VipPackageId, Amount, PaymentMethod, Status,
                                  GatewayTransactionId, FailureReason, ExpiresAt, CreatedAt, PaidAt)
        VALUES (NEWID(), 900000000000000 + @n,
                @userId,
                @pkg, @amount, @method, @status,
                'SEED-' + CAST(@n AS VARCHAR(10)),
                CASE @status WHEN 'Cancelled' THEN N'Hết hạn thanh toán' WHEN 'Failed' THEN N'Thanh toán không thành công' END,
                DATEADD(MINUTE, 15, @created), @created,
                CASE WHEN @status = 'Paid' THEN DATEADD(MINUTE, 2, @created) END);

        SET @n += 1;
        SET @i += 1;
    END
    SET @day -= 1;
END

PRINT N'✅ Đã tạo ' + CAST(@n AS NVARCHAR(10)) + N' giao dịch demo.';
GO

-- ── Xóa dữ liệu demo (bôi đen 1 dòng dưới rồi F5) ───────────────────────────
-- DELETE FROM Transactions WHERE GatewayTransactionId LIKE 'SEED-%';
