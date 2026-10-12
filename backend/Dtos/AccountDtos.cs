namespace Blush.Api.Dtos
{
    // Xóa tài khoản: xác nhận lại danh tính trước khi xóa.
    //   Tài khoản có mật khẩu -> Password
    //   Tài khoản chỉ đăng nhập Google -> GoogleIdToken (app mở lại hộp thoại Google)
    public class DeleteAccountRequest
    {
        public string? Password { get; set; }
        public string? GoogleIdToken { get; set; }
    }
}
