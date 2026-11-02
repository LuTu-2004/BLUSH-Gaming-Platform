-- ============================================================================
-- Nâng 1 tài khoản đã đăng ký thành Admin (dùng trên server thật, nơi không có tài khoản demo).
--   1. Đăng ký tài khoản trong app BLUSH bằng email của bạn (xác minh email xong).
--   2. Sửa email ở dòng @Email bên dưới rồi chạy file này trên database đó.
-- Mật khẩu chỉ bạn biết vì do bạn tự đặt lúc đăng ký, script không chứa mật khẩu nào.
-- ============================================================================
-- Bắt buộc khi sửa bảng có cột tính toán PERSISTED (Users.CurrentLevel); SSMS / Azure Query editor bật sẵn, sqlcmd thì không
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @Email VARCHAR(255) = 'email-cua-ban@gmail.com';

DECLARE @UserId UNIQUEIDENTIFIER = (SELECT Id FROM Users WHERE Email = @Email);
IF @UserId IS NULL
BEGIN
    PRINT N'❌ Không có tài khoản ' + @Email + N'. Đăng ký trong app trước rồi chạy lại.';
    RETURN;
END

UPDATE Users SET RoleId = (SELECT Id FROM Roles WHERE RoleName = 'Admin') WHERE Id = @UserId;
PRINT N'✅ ' + @Email + N' đã là Admin. Đăng xuất rồi đăng nhập lại trong app để vào trang quản trị.';
