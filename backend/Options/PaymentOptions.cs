namespace Blush.Api.Options
{
    // Đọc từ mục "Payment" trong appsettings.json.
    //
    // Mode = "Mock" (mặc định): không gọi cổng thật, app hiện trang thanh toán giả lập -> demo không cần mạng/key.
    // Mode = "Sandbox": gọi môi trường thử của MoMo / VNPay / ZaloPay. Cần:
    //   - PublicBaseUrl: địa chỉ backend mà cổng thanh toán gọi tới được (VD: link ngrok https://abc.ngrok-free.app)
    //   - Key của từng cổng, đặt bằng user-secrets (không ghi vào file này), VD:
    //       dotnet user-secrets set "Payment:VnPay:TmnCode" "<mã website>"
    //       dotnet user-secrets set "Payment:VnPay:HashSecret" "<chuỗi bí mật>"
    //   Cổng nào chưa có key thì app sẽ hiện "Chưa hỗ trợ" và không cho chọn.
    public class PaymentOptions
    {
        public const string SectionName = "Payment";
        public const string MockMode = "Mock";
        public const string SandboxMode = "Sandbox";

        public string Mode { get; set; } = MockMode;
        public string PublicBaseUrl { get; set; } = "http://localhost:5000";

        /// Giao dịch chưa trả sau bấy nhiêu phút thì tự hủy
        public int PendingMinutes { get; set; } = 15;

        public MomoOptions Momo { get; set; } = new();
        public VnPayOptions VnPay { get; set; } = new();
        public ZaloPayOptions ZaloPay { get; set; } = new();
        public VietQrOptions VietQr { get; set; } = new();

        public bool IsMock => !string.Equals(Mode, SandboxMode, StringComparison.OrdinalIgnoreCase);
    }

    public class MomoOptions
    {
        public string Endpoint { get; set; } = "https://test-payment.momo.vn/v2/gateway/api/create";
        public string PartnerCode { get; set; } = string.Empty;
        public string AccessKey { get; set; } = string.Empty;
        public string SecretKey { get; set; } = string.Empty;

        public bool IsConfigured => PartnerCode != "" && AccessKey != "" && SecretKey != "";
    }

    public class VnPayOptions
    {
        public string PaymentUrl { get; set; } = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
        public string TmnCode { get; set; } = string.Empty;
        public string HashSecret { get; set; } = string.Empty;

        public bool IsConfigured => TmnCode != "" && HashSecret != "";
    }

    public class ZaloPayOptions
    {
        public string Endpoint { get; set; } = "https://sb-openapi.zalopay.vn/v2/create";
        public string AppId { get; set; } = string.Empty;
        public string Key1 { get; set; } = string.Empty; // ký đơn tạo mới
        public string Key2 { get; set; } = string.Empty; // kiểm tra callback

        public bool IsConfigured => AppId != "" && Key1 != "" && Key2 != "";
    }

    public class VietQrOptions
    {
        // Tài khoản nhận tiền (demo). Đổi thành tài khoản thật của nhóm khi chạy thật.
        public string BankCode { get; set; } = "MB";
        public string BankName { get; set; } = "MB Bank";
        public string AccountNo { get; set; } = "0388888888";
        public string AccountName { get; set; } = "BLUSH GAMING";
    }
}
