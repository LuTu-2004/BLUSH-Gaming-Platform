-- ============================================================================
-- MIGRATION 005: Thanh toán nhiều cổng (MoMo, VNPay, ZaloPay, VietQR) + gói 3 tháng
-- Chạy sau 004. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thêm thông tin giao dịch
IF COL_LENGTH('Transactions', 'GatewayTransactionId') IS NULL
    ALTER TABLE Transactions ADD GatewayTransactionId VARCHAR(100) NULL;  -- Mã giao dịch phía MoMo/VNPay/ZaloPay
IF COL_LENGTH('Transactions', 'FailureReason') IS NULL
    ALTER TABLE Transactions ADD FailureReason NVARCHAR(255) NULL;        -- Lý do thất bại / hủy
IF COL_LENGTH('Transactions', 'ExpiresAt') IS NULL
    ALTER TABLE Transactions ADD ExpiresAt DATETIME2 NULL;                -- Quá hạn mà chưa trả -> tự hủy
GO

-- 2. Chỉ nhận các phương thức đã hỗ trợ ('VietQR_PayOS' là giá trị cũ, giữ lại cho dữ liệu cũ)
IF OBJECT_ID('CK_Transactions_PaymentMethod', 'C') IS NULL
    ALTER TABLE Transactions ADD CONSTRAINT CK_Transactions_PaymentMethod
        CHECK (PaymentMethod IN ('MoMo', 'VNPay', 'ZaloPay', 'VietQR', 'VietQR_PayOS'));
GO

-- 3. Index cho Dashboard doanh thu (lọc theo trạng thái + thời gian)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Transactions_Status_CreatedAt')
    CREATE INDEX IX_Transactions_Status_CreatedAt ON Transactions(Status, CreatedAt);
GO

-- 4. Gói Pro 3 tháng (rẻ hơn mua lẻ 3 tháng: 147.000đ -> 129.000đ)
IF NOT EXISTS (SELECT 1 FROM VipPackages WHERE PackageCode = 'quarter_pro')
    INSERT INTO VipPackages (PackageCode, PackageName, Price, DurationDays, AiTokenLimit, Description, Badge) VALUES
    ('quarter_pro', N'BLUSH Pass Pro 3 tháng', 129000, 90, 150000, N'Gói Pro 3 tháng, tiết kiệm 12%', N'TIẾT KIỆM 12%');
GO

PRINT N'✅ Migration 005 (thanh toán nhiều cổng) xong!';
GO
