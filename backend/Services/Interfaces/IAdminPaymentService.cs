using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Dashboard doanh thu cho Admin
    // ============================================================
    public interface IAdminPaymentService
    {
        /// Số liệu [days] ngày gần nhất (tính cả hôm nay)
        Task<PaymentSummaryDto> GetSummaryAsync(int days);

        /// [status], [method]: null = tất cả. [search]: email / tên / mã đơn.
        Task<PagedResult<AdminTransactionDto>> GetTransactionsAsync(string? status, string? method, string? search, int page, int pageSize);

        /// Admin xác nhận đã nhận tiền chuyển khoản VietQR (đối soát sao kê ngân hàng)
        Task<ServiceResult<AdminTransactionDto>> ConfirmBankTransferAsync(long orderCode, Guid adminId);
    }
}
