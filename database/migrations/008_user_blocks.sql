-- ============================================================================
-- MIGRATION 008: Chặn người dùng (Google Play bắt buộc với app có chat giữa người lạ)
-- Chạy sau 007. Chỉ THÊM, không xóa dữ liệu. Chạy nhiều lần cũng không sao.
-- A chặn B -> 2 người không nhắn tin được cho nhau, phòng chat cũ bị ẩn, không gợi ý ghép đội với nhau.
-- ============================================================================
USE BlushDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('UserBlocks') IS NULL
BEGIN
    CREATE TABLE UserBlocks (
        BlockerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
        BlockedId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        PRIMARY KEY (BlockerId, BlockedId),
        CONSTRAINT CK_UserBlocks_NotSelf CHECK (BlockerId <> BlockedId)
    );
    -- Tìm "ai đã chặn tôi" (chiều ngược lại của khóa chính)
    CREATE INDEX IX_UserBlocks_Blocked ON UserBlocks(BlockedId);
END
GO

PRINT N'✅ Migration 008 (chặn người dùng) xong!';
GO
