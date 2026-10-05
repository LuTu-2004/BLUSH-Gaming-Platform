using Blush.Api.DataAccess.Entities;
using Blush.Api.Options;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Payments
{
    // Chuyển khoản ngân hàng bằng mã VietQR (ảnh QR tạo bởi img.vietqr.io, app ngân hàng nào cũng quét được).
    // Ngân hàng không tự báo về backend, nên giao dịch ở trạng thái Pending tới khi:
    //   - Chế độ Mock: bấm nút giả lập "ngân hàng đã nhận tiền" trong app
    //   - Chạy thật: Admin đối soát sao kê rồi xác nhận (hoặc nối PayOS/Casso webhook sau này)
    public class VietQrGateway : IPaymentGateway
    {
        private readonly VietQrOptions _options;

        public VietQrGateway(IOptions<PaymentOptions> options)
        {
            _options = options.Value.VietQr;
        }

        public string Method => PaymentMethods.VietQr;

        public bool IsConfigured => _options.AccountNo != "";

        public static string TransferContent(long orderCode) => $"BLUSH {orderCode}";

        public Task<GatewayCheckout> CreateAsync(GatewayOrder order)
        {
            var content = TransferContent(order.OrderCode);
            var qrImageUrl = $"https://img.vietqr.io/image/{_options.BankCode}-{_options.AccountNo}-compact2.png"
                + $"?amount={order.Amount}&addInfo={Uri.EscapeDataString(content)}&accountName={Uri.EscapeDataString(_options.AccountName)}";

            return Task.FromResult(new GatewayCheckout
            {
                QrImageUrl = qrImageUrl,
                BankTransfer = new BankTransferInfo
                {
                    BankName = _options.BankName,
                    AccountNo = _options.AccountNo,
                    AccountName = _options.AccountName,
                    Content = content,
                },
            });
        }
    }
}
