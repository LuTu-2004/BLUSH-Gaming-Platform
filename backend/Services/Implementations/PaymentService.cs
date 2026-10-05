using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Options;
using Blush.Api.Services.Interfaces;
using Blush.Api.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Mua gói VIP
    //
    //   1. CreateCheckout: tạo Transactions (Pending) + đơn bên cổng -> trả link/QR cho app
    //   2. Người dùng trả tiền. Cổng báo kết quả về (hoặc bấm giả lập ở chế độ Mock)
    //   3. ApplyGatewayResult: Pending -> Paid + thêm 1 dòng UserSubscriptions (kích hoạt / gia hạn VIP)
    // ============================================================
    public class PaymentService : IPaymentService
    {
        private const string ExpiredReason = "Hết hạn thanh toán";

        private static readonly Dictionary<string, (string Name, string Description)> MethodInfo = new()
        {
            [PaymentMethods.MoMo] = ("Ví MoMo", "Mở app MoMo hoặc quét mã để thanh toán"),
            [PaymentMethods.VnPay] = ("VNPay", "Thẻ ATM nội địa, Visa/Master, QR ngân hàng"),
            [PaymentMethods.ZaloPay] = ("Ví ZaloPay", "Thanh toán nhanh qua app ZaloPay"),
            [PaymentMethods.VietQr] = ("Chuyển khoản VietQR", "Quét mã bằng app ngân hàng bất kỳ"),
        };

        private readonly BlushDbContext _context;
        private readonly PaymentOptions _options;
        private readonly Dictionary<string, IPaymentGateway> _gateways;
        private readonly ILogger<PaymentService> _logger;

        public PaymentService(BlushDbContext context, IOptions<PaymentOptions> options, IEnumerable<IPaymentGateway> gateways, ILogger<PaymentService> logger)
        {
            _context = context;
            _options = options.Value;
            _gateways = gateways.ToDictionary(g => g.Method);
            _logger = logger;
        }

        public async Task<List<VipPackageDto>> GetPackagesAsync() =>
            await _context.VipPackages
                .Where(p => p.IsActive)
                .OrderBy(p => p.Price)
                .Select(p => new VipPackageDto
                {
                    Code = p.PackageCode,
                    Name = p.PackageName,
                    Price = p.Price,
                    DurationDays = p.DurationDays,
                    AiTokenLimit = p.AiTokenLimit,
                    Description = p.Description,
                    Badge = p.Badge,
                })
                .ToListAsync();

        public List<PaymentMethodDto> GetMethods() =>
            MethodInfo.Select(m => new PaymentMethodDto
            {
                Code = m.Key,
                Name = m.Value.Name,
                Description = m.Value.Description,
                IsAvailable = IsMethodAvailable(m.Key),
            }).ToList();

        // Mock: cổng nào cũng dùng được. Sandbox: cần có key (VietQR không cần key).
        private bool IsMethodAvailable(string method) =>
            _gateways.TryGetValue(method, out var gateway) && (_options.IsMock || gateway.IsConfigured);

        public async Task<ServiceResult<CheckoutDto>> CreateCheckoutAsync(Guid userId, CheckoutRequest request, string clientIp)
        {
            var package = await _context.VipPackages.FirstOrDefaultAsync(p => p.PackageCode == request.PackageCode && p.IsActive);
            if (package == null)
            {
                return ServiceResult<CheckoutDto>.Fail(StatusCodes.Status404NotFound, $"Không tìm thấy gói '{request.PackageCode}'!");
            }
            if (!IsMethodAvailable(request.Method))
            {
                return ServiceResult<CheckoutDto>.Fail(StatusCodes.Status400BadRequest, "Phương thức thanh toán này chưa được hỗ trợ.");
            }

            var now = DateTime.UtcNow;

            // Mỗi người chỉ giữ 1 đơn đang chờ: tạo đơn mới thì hủy đơn cũ chưa trả
            await _context.Transactions
                .Where(t => t.UserId == userId && t.Status == TransactionStatus.Pending)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(t => t.Status, TransactionStatus.Cancelled)
                    .SetProperty(t => t.FailureReason, "Đã tạo giao dịch mới"));

            var transaction = new Transaction
            {
                Id = Guid.NewGuid(),
                // Mã đơn: thời điểm (ms) x 100 + số ngẫu nhiên -> không trùng, vẫn là số (VNPay/ZaloPay yêu cầu)
                OrderCode = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 100 + Random.Shared.Next(100),
                UserId = userId,
                VipPackageId = package.Id,
                Amount = package.Price,
                PaymentMethod = request.Method,
                Status = TransactionStatus.Pending,
                ExpiresAt = now.AddMinutes(_options.PendingMinutes),
                CreatedAt = now,
            };
            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            var dto = new CheckoutDto
            {
                OrderCode = transaction.OrderCode,
                Amount = transaction.Amount,
                PackageCode = package.PackageCode,
                PackageName = package.PackageName,
                Method = transaction.PaymentMethod,
                Status = transaction.Status,
                ExpiresAt = transaction.ExpiresAt,
                IsMock = _options.IsMock,
            };

            // Mock: MoMo/VNPay/ZaloPay không gọi cổng thật, app tự hiện trang giả lập.
            // VietQR luôn tạo QR thật (chỉ là ảnh, không cần key).
            if (_options.IsMock && request.Method != PaymentMethods.VietQr)
            {
                return ServiceResult<CheckoutDto>.Ok(dto);
            }

            try
            {
                var checkout = await _gateways[request.Method].CreateAsync(new GatewayOrder(
                    transaction.OrderCode, (long)transaction.Amount, package.PackageCode, NormalizeIp(clientIp), transaction.ExpiresAt!.Value));
                dto.PaymentUrl = checkout.PaymentUrl;
                dto.QrImageUrl = checkout.QrImageUrl;
                dto.BankTransfer = checkout.BankTransfer;
                return ServiceResult<CheckoutDto>.Ok(dto);
            }
            catch (Exception ex) when (ex is PaymentGatewayException or HttpRequestException or TaskCanceledException)
            {
                _logger.LogWarning(ex, "Tạo đơn {Method} thất bại cho giao dịch {OrderCode}", request.Method, transaction.OrderCode);
                transaction.Status = TransactionStatus.Failed;
                transaction.FailureReason = "Không tạo được đơn bên cổng thanh toán";
                await _context.SaveChangesAsync();
                return ServiceResult<CheckoutDto>.Fail(StatusCodes.Status502BadGateway, "Cổng thanh toán đang lỗi, vui lòng thử phương thức khác.");
            }
        }

        public async Task<ServiceResult<TransactionDto>> GetTransactionAsync(Guid userId, long orderCode)
        {
            await ExpireStaleAsync(userId);
            var dto = await ToDto(_context.Transactions.Where(t => t.UserId == userId && t.OrderCode == orderCode)).FirstOrDefaultAsync();
            return dto == null
                ? ServiceResult<TransactionDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy giao dịch!")
                : ServiceResult<TransactionDto>.Ok(dto);
        }

        public async Task<List<TransactionDto>> GetMyTransactionsAsync(Guid userId)
        {
            await ExpireStaleAsync(userId);
            return await ToDto(_context.Transactions.Where(t => t.UserId == userId).OrderByDescending(t => t.CreatedAt).Take(50)).ToListAsync();
        }

        public async Task<ServiceResult<TransactionDto>> CancelAsync(Guid userId, long orderCode)
        {
            await _context.Transactions
                .Where(t => t.UserId == userId && t.OrderCode == orderCode && t.Status == TransactionStatus.Pending)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(t => t.Status, TransactionStatus.Cancelled)
                    .SetProperty(t => t.FailureReason, "Bạn đã hủy giao dịch"));
            return await GetTransactionAsync(userId, orderCode);
        }

        public async Task<ServiceResult<TransactionDto>> CompleteMockAsync(Guid userId, long orderCode, bool success)
        {
            if (!_options.IsMock)
            {
                return ServiceResult<TransactionDto>.Fail(StatusCodes.Status404NotFound, "Chỉ dùng được ở chế độ thanh toán giả lập.");
            }

            var transaction = await _context.Transactions.AsNoTracking().FirstOrDefaultAsync(t => t.UserId == userId && t.OrderCode == orderCode);
            if (transaction == null)
            {
                return ServiceResult<TransactionDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy giao dịch!");
            }

            await ApplyGatewayResultAsync(new GatewayResult(
                orderCode, success, (long)transaction.Amount, $"MOCK-{orderCode}", success ? null : "Giao dịch bị từ chối (giả lập)"));
            return await GetTransactionAsync(userId, orderCode);
        }

        public async Task<GatewayApplyOutcome> ApplyGatewayResultAsync(GatewayResult result)
        {
            var transaction = await _context.Transactions.Include(t => t.VipPackage).FirstOrDefaultAsync(t => t.OrderCode == result.OrderCode);
            if (transaction == null) return GatewayApplyOutcome.OrderNotFound;
            if (transaction.Status == TransactionStatus.Paid) return GatewayApplyOutcome.AlreadyConfirmed;

            var now = DateTime.UtcNow;

            if (!result.Success)
            {
                // Thất bại chỉ ghi khi còn đang chờ (không ghi đè đơn đã hủy)
                var updated = await _context.Transactions
                    .Where(t => t.Id == transaction.Id && t.Status == TransactionStatus.Pending)
                    .ExecuteUpdateAsync(s => s
                        .SetProperty(t => t.Status, TransactionStatus.Failed)
                        .SetProperty(t => t.FailureReason, result.Message ?? "Thanh toán không thành công")
                        .SetProperty(t => t.GatewayTransactionId, result.GatewayTransactionId));
                return updated > 0 ? GatewayApplyOutcome.Applied : GatewayApplyOutcome.AlreadyConfirmed;
            }

            if (result.Amount != (long)transaction.Amount)
            {
                _logger.LogWarning("Giao dịch {OrderCode}: cổng báo {Paid}đ nhưng đơn là {Amount}đ", result.OrderCode, result.Amount, transaction.Amount);
                return GatewayApplyOutcome.AmountMismatch;
            }

            // Tiền đã trừ thật thì vẫn kích hoạt, kể cả khi đơn đã bị hủy/hết hạn bên BLUSH trước đó.
            // Chỉ 1 request đổi được sang Paid (điều kiện Status <> Paid) -> cổng gọi lại nhiều lần cũng không cộng VIP 2 lần.
            await using var dbTransaction = await _context.Database.BeginTransactionAsync();
            var changed = await _context.Transactions
                .Where(t => t.Id == transaction.Id && t.Status != TransactionStatus.Paid)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(t => t.Status, TransactionStatus.Paid)
                    .SetProperty(t => t.PaidAt, now)
                    .SetProperty(t => t.FailureReason, (string?)null)
                    .SetProperty(t => t.GatewayTransactionId, result.GatewayTransactionId));
            if (changed == 0) return GatewayApplyOutcome.AlreadyConfirmed;

            // Mua lại cùng gói khi còn hạn -> nối tiếp sau ngày hết hạn. Gói khác -> bắt đầu ngay.
            var currentEnd = await _context.UserSubscriptions
                .Where(s => s.UserId == transaction.UserId && s.VipPackageId == transaction.VipPackageId && s.EndAt > now)
                .MaxAsync(s => (DateTime?)s.EndAt);
            var startAt = currentEnd ?? now;

            _context.UserSubscriptions.Add(new UserSubscription
            {
                UserId = transaction.UserId,
                VipPackageId = transaction.VipPackageId,
                TransactionId = transaction.Id,
                StartAt = startAt,
                EndAt = startAt.AddDays(transaction.VipPackage.DurationDays),
            });
            await _context.SaveChangesAsync();
            await dbTransaction.CommitAsync();
            return GatewayApplyOutcome.Applied;
        }

        // Đơn quá hạn mà chưa trả -> Cancelled (chạy mỗi khi người dùng xem giao dịch)
        private Task<int> ExpireStaleAsync(Guid userId)
        {
            var now = DateTime.UtcNow;
            return _context.Transactions
                .Where(t => t.UserId == userId && t.Status == TransactionStatus.Pending && t.ExpiresAt < now)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(t => t.Status, TransactionStatus.Cancelled)
                    .SetProperty(t => t.FailureReason, ExpiredReason));
        }

        private static IQueryable<TransactionDto> ToDto(IQueryable<Transaction> query) =>
            query.Select(t => new TransactionDto
            {
                OrderCode = t.OrderCode,
                Amount = t.Amount,
                PackageCode = t.VipPackage.PackageCode,
                PackageName = t.VipPackage.PackageName,
                Method = t.PaymentMethod,
                Status = t.Status,
                FailureReason = t.FailureReason,
                CreatedAt = t.CreatedAt,
                PaidAt = t.PaidAt,
                ExpiresAt = t.ExpiresAt,
            });

        // VNPay cần IPv4; chạy local thường ra "::1"
        private static string NormalizeIp(string ip) => ip is "" or "::1" ? "127.0.0.1" : ip.Replace("::ffff:", "");
    }
}
