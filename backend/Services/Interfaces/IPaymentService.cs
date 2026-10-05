using Blush.Api.Dtos;
using Blush.Api.Services.Payments;

namespace Blush.Api.Services.Interfaces
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Mua gói VIP
    // ============================================================
    public interface IPaymentService
    {
        Task<List<VipPackageDto>> GetPackagesAsync();

        List<PaymentMethodDto> GetMethods();

        /// Tạo giao dịch Pending + đơn bên cổng thanh toán
        Task<ServiceResult<CheckoutDto>> CreateCheckoutAsync(Guid userId, CheckoutRequest request, string clientIp);

        /// App hỏi lại trạng thái (vài giây 1 lần) trong lúc chờ người dùng trả tiền
        Task<ServiceResult<TransactionDto>> GetTransactionAsync(Guid userId, long orderCode);

        Task<List<TransactionDto>> GetMyTransactionsAsync(Guid userId);

        Task<ServiceResult<TransactionDto>> CancelAsync(Guid userId, long orderCode);

        /// Chỉ chế độ Mock: giả lập cổng báo thành công / thất bại
        Task<ServiceResult<TransactionDto>> CompleteMockAsync(Guid userId, long orderCode, bool success);

        /// Hỏi thẳng cổng trạng thái đơn rồi cập nhật (dự phòng khi webhook/IPN không tới). [userId] null = không kiểm chủ đơn.
        Task ReconcileAsync(Guid? userId, long orderCode);

        /// Cổng thanh toán báo kết quả (đã kiểm tra chữ ký). Gọi nhiều lần cũng chỉ kích hoạt VIP 1 lần.
        Task<GatewayApplyOutcome> ApplyGatewayResultAsync(GatewayResult result);
    }

    public enum GatewayApplyOutcome
    {
        Applied,          // đã cập nhật giao dịch
        AlreadyConfirmed, // đã xử lý từ lần báo trước
        OrderNotFound,
        AmountMismatch,
    }
}
