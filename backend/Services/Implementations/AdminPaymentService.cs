using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Blush.Api.Services.Payments;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Dashboard doanh thu cho Admin
    // Doanh thu chỉ tính giao dịch Paid, theo thời điểm PaidAt, chia ngày theo giờ Việt Nam.
    // ============================================================
    public class AdminPaymentService : IAdminPaymentService
    {
        private static readonly TimeSpan VietnamOffset = TimeSpan.FromHours(7);

        private readonly BlushDbContext _context;
        private readonly IPaymentService _paymentService;

        public AdminPaymentService(BlushDbContext context, IPaymentService paymentService)
        {
            _context = context;
            _paymentService = paymentService;
        }

        // 00:00 ngày [day] giờ Việt Nam, đổi ra UTC để so với DB
        private static DateTime StartOfVietnamDayUtc(DateOnly day) => day.ToDateTime(TimeOnly.MinValue) - VietnamOffset;

        private static DateOnly VietnamDate(DateTime utc) => DateOnly.FromDateTime(utc + VietnamOffset);

        public async Task<PaymentSummaryDto> GetSummaryAsync(int days)
        {
            days = Math.Clamp(days, 1, 90);
            var now = DateTime.UtcNow;
            var today = VietnamTime.Today;
            var rangeStartDay = today.AddDays(-(days - 1));
            var monthStartDay = new DateOnly(today.Year, today.Month, 1);
            var rangeStartUtc = StartOfVietnamDayUtc(rangeStartDay);
            var monthStartUtc = StartOfVietnamDayUtc(monthStartDay);
            var fromUtc = rangeStartUtc < monthStartUtc ? rangeStartUtc : monthStartUtc;

            // Giao dịch đã trả từ đầu tháng / đầu khoảng (lấy về rồi gom nhóm trong bộ nhớ, đủ nhanh ở quy mô hiện tại)
            var paid = await _context.Transactions.AsNoTracking()
                .Where(t => t.Status == TransactionStatus.Paid && t.PaidAt >= fromUtc)
                .Select(t => new { PaidAt = t.PaidAt!.Value, t.Amount, t.PaymentMethod, t.VipPackage.PackageCode, t.VipPackage.PackageName })
                .ToListAsync();
            var paidInRange = paid.Where(p => p.PaidAt >= rangeStartUtc).ToList();

            // Giao dịch được tạo trong khoảng, đếm theo trạng thái
            var statusCounts = await _context.Transactions.AsNoTracking()
                .Where(t => t.CreatedAt >= rangeStartUtc)
                .GroupBy(t => t.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToDictionaryAsync(g => g.Status, g => g.Count);
            int CountOf(string status) => statusCounts.GetValueOrDefault(status);
            var finished = CountOf(TransactionStatus.Paid) + CountOf(TransactionStatus.Failed) + CountOf(TransactionStatus.Cancelled);

            var revenueByDay = paidInRange
                .GroupBy(p => VietnamDate(p.PaidAt))
                .ToDictionary(g => g.Key, g => (Revenue: g.Sum(p => p.Amount), Count: g.Count()));

            return new PaymentSummaryDto
            {
                Days = days,
                RevenueToday = paid.Where(p => VietnamDate(p.PaidAt) == today).Sum(p => p.Amount),
                RevenueThisMonth = paid.Where(p => p.PaidAt >= monthStartUtc).Sum(p => p.Amount),
                RevenueInRange = paidInRange.Sum(p => p.Amount),
                TransactionCount = statusCounts.Values.Sum(),
                PaidCount = CountOf(TransactionStatus.Paid),
                PendingCount = CountOf(TransactionStatus.Pending),
                SuccessRate = finished == 0 ? null : Math.Round(100.0 * CountOf(TransactionStatus.Paid) / finished, 1),
                ActiveVipCount = await _context.UserSubscriptions
                    .Where(s => s.StartAt <= now && s.EndAt > now)
                    .Select(s => s.UserId)
                    .Distinct()
                    .CountAsync(),
                TotalUsers = await _context.Users.CountAsync(u => u.RoleId == Role.UserId),
                NewUsersInRange = await _context.Users.CountAsync(u => u.RoleId == Role.UserId && u.CreatedAt >= rangeStartUtc),

                // Đủ mọi ngày trong khoảng (ngày không có doanh thu = 0) để biểu đồ không bị hụt cột
                Daily = Enumerable.Range(0, days)
                    .Select(i => rangeStartDay.AddDays(i))
                    .Select(d => new DailyRevenueDto
                    {
                        Date = d,
                        Revenue = revenueByDay.TryGetValue(d, out var v) ? v.Revenue : 0,
                        Count = revenueByDay.TryGetValue(d, out var c) ? c.Count : 0,
                    })
                    .ToList(),
                ByMethod = paidInRange
                    .GroupBy(p => p.PaymentMethod)
                    .Select(g => new BreakdownDto { Key = g.Key, Label = PaymentMethods.LabelOf(g.Key), Revenue = g.Sum(p => p.Amount), Count = g.Count() })
                    .OrderByDescending(b => b.Revenue)
                    .ToList(),
                ByPackage = paidInRange
                    .GroupBy(p => new { p.PackageCode, p.PackageName })
                    .Select(g => new BreakdownDto { Key = g.Key.PackageCode, Label = g.Key.PackageName, Revenue = g.Sum(p => p.Amount), Count = g.Count() })
                    .OrderByDescending(b => b.Revenue)
                    .ToList(),
            };
        }

        public async Task<PagedResult<AdminTransactionDto>> GetTransactionsAsync(string? status, string? method, string? search, int page, int pageSize)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _context.Transactions.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(status)) query = query.Where(t => t.Status == status);
            if (!string.IsNullOrWhiteSpace(method)) query = query.Where(t => t.PaymentMethod == method);
            if (!string.IsNullOrWhiteSpace(search))
            {
                var keyword = search.Trim();
                var hasOrderCode = long.TryParse(keyword, out var orderCode);
                query = query.Where(t =>
                    (hasOrderCode && t.OrderCode == orderCode)
                    || _context.Users.Any(u => u.Id == t.UserId && (u.Email.Contains(keyword) || (u.Profile != null && u.Profile.DisplayName.Contains(keyword)))));
            }

            var total = await query.CountAsync();
            var items = await ToDto(query.OrderByDescending(t => t.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize)).ToListAsync();
            return new PagedResult<AdminTransactionDto> { Items = items, Total = total, Page = page, PageSize = pageSize };
        }

        public async Task<ServiceResult<AdminTransactionDto>> ConfirmBankTransferAsync(long orderCode, Guid adminId)
        {
            var transaction = await _context.Transactions.AsNoTracking().FirstOrDefaultAsync(t => t.OrderCode == orderCode);
            if (transaction == null)
            {
                return ServiceResult<AdminTransactionDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy giao dịch!");
            }
            // MoMo do cổng tự xác nhận. VietQR thường do PayOS tự xác nhận; nút này cho trường hợp người dùng
            // chuyển sai nội dung/chuyển tay mà PayOS không khớp được đơn -> Admin đối soát sao kê rồi xác nhận
            if (transaction.PaymentMethod is not (PaymentMethods.VietQr or PaymentMethods.VietQrPayOs))
            {
                return ServiceResult<AdminTransactionDto>.Fail(StatusCodes.Status400BadRequest, "Chỉ xác nhận thủ công được giao dịch chuyển khoản VietQR.");
            }
            if (transaction.Status == TransactionStatus.Paid)
            {
                return ServiceResult<AdminTransactionDto>.Fail(StatusCodes.Status400BadRequest, "Giao dịch này đã được xác nhận rồi.");
            }

            await _paymentService.ApplyGatewayResultAsync(new GatewayResult(
                orderCode, true, (long)transaction.Amount, $"MANUAL-{adminId:N}", null));

            var dto = await ToDto(_context.Transactions.Where(t => t.OrderCode == orderCode)).FirstAsync();
            return ServiceResult<AdminTransactionDto>.Ok(dto);
        }

        private IQueryable<AdminTransactionDto> ToDto(IQueryable<Transaction> query) =>
            from t in query
            join u in _context.Users on t.UserId equals u.Id
            select new AdminTransactionDto
            {
                OrderCode = t.OrderCode,
                UserEmail = u.Email,
                UserDisplayName = u.Profile != null ? u.Profile.DisplayName : u.Email,
                Amount = t.Amount,
                PackageName = t.VipPackage.PackageName,
                Method = t.PaymentMethod,
                Status = t.Status,
                FailureReason = t.FailureReason,
                GatewayTransactionId = t.GatewayTransactionId,
                CreatedAt = t.CreatedAt,
                PaidAt = t.PaidAt,
            };
    }
}
