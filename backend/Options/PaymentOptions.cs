namespace Blush.Api.Options
{
    // Đọc từ mục "Payment" trong appsettings.json.
    //
    // Mode:
    //   "Mock"       (mặc định) không gọi cổng thật, app hiện trang thanh toán giả lập -> demo không cần mạng/key
    //   "Sandbox"    MoMo môi trường test (tiền giả). VietQR vẫn đi qua PayOS (PayOS không có môi trường test)
    //   "Production" TIỀN THẬT: MoMo production + PayOS
    //
    // Chạy Sandbox/Production cần:
    //   - PublicBaseUrl: địa chỉ https của backend mà MoMo/PayOS gọi tới được (VD link ngrok https://abc.ngrok-free.app)
    //   - Key đặt bằng user-secrets, KHÔNG ghi vào appsettings.json (file này bị đẩy lên GitHub):
    //       dotnet user-secrets set "Payment:Momo:PartnerCode" "..."
    //       dotnet user-secrets set "Payment:Momo:AccessKey" "..."
    //       dotnet user-secrets set "Payment:Momo:SecretKey" "..."
    //       dotnet user-secrets set "Payment:PayOs:ClientId" "..."
    //       dotnet user-secrets set "Payment:PayOs:ApiKey" "..."
    //       dotnet user-secrets set "Payment:PayOs:ChecksumKey" "..."
    //   Cổng nào chưa có key thì app hiện "Chưa hỗ trợ" và không cho chọn.
    public class PaymentOptions
    {
        public const string SectionName = "Payment";
        public const string MockMode = "Mock";
        public const string SandboxMode = "Sandbox";
        public const string ProductionMode = "Production";

        public string Mode { get; set; } = MockMode;
        public string PublicBaseUrl { get; set; } = "http://localhost:5000";

        /// Giao dịch chưa trả sau bấy nhiêu phút thì tự hủy
        public int PendingMinutes { get; set; } = 15;

        public MomoOptions Momo { get; set; } = new();
        public PayOsOptions PayOs { get; set; } = new();
        public VietQrOptions VietQr { get; set; } = new();

        public bool IsProduction => string.Equals(Mode, ProductionMode, StringComparison.OrdinalIgnoreCase);
        public bool IsSandbox => string.Equals(Mode, SandboxMode, StringComparison.OrdinalIgnoreCase);
        public bool IsMock => !IsProduction && !IsSandbox;
    }

    public class MomoOptions
    {
        /// Để trống = tự chọn theo Mode (Production: payment.momo.vn, Sandbox: test-payment.momo.vn)
        public string? BaseUrl { get; set; }
        public string PartnerCode { get; set; } = string.Empty;
        public string AccessKey { get; set; } = string.Empty;
        public string SecretKey { get; set; } = string.Empty;

        public bool IsConfigured => PartnerCode != "" && AccessKey != "" && SecretKey != "";
    }

    // PayOS (payos.vn): tạo mã VietQR cho từng đơn, tiền vào thẳng tài khoản ngân hàng của nhóm,
    // PayOS báo về qua webhook khi tiền tới -> tự kích hoạt VIP. Lấy key ở my.payos.vn > Kênh thanh toán.
    public class PayOsOptions
    {
        public string BaseUrl { get; set; } = "https://api-merchant.payos.vn";
        public string ClientId { get; set; } = string.Empty;
        public string ApiKey { get; set; } = string.Empty;
        public string ChecksumKey { get; set; } = string.Empty;

        public bool IsConfigured => ClientId != "" && ApiKey != "" && ChecksumKey != "";
    }

    // Chỉ dùng ở chế độ Mock: QR chuyển khoản tĩnh để demo (không tự xác nhận được).
    public class VietQrOptions
    {
        public string BankCode { get; set; } = "MB";
        public string BankName { get; set; } = "MB Bank";
        public string AccountNo { get; set; } = "0388888888";
        public string AccountName { get; set; } = "BLUSH GAMING";
    }
}
