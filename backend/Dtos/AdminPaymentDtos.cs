namespace Blush.Api.Dtos
{
    // ── Dashboard doanh thu (GET api/admin/payments/summary) ─────────
    public class PaymentSummaryDto
    {
        public int Days { get; set; }

        // Doanh thu (chỉ giao dịch Paid, tính theo ngày giờ Việt Nam)
        public decimal RevenueToday { get; set; }
        public decimal RevenueThisMonth { get; set; }
        public decimal RevenueInRange { get; set; }

        // Giao dịch tạo trong khoảng thời gian
        public int TransactionCount { get; set; }
        public int PaidCount { get; set; }
        public int PendingCount { get; set; }

        /// Tỉ lệ thành công = Paid / (Paid + Failed + Cancelled), 0-100. Null nếu chưa có giao dịch kết thúc.
        public double? SuccessRate { get; set; }

        public int ActiveVipCount { get; set; }
        public int TotalUsers { get; set; }
        public int NewUsersInRange { get; set; }

        public List<DailyRevenueDto> Daily { get; set; } = new();
        public List<BreakdownDto> ByMethod { get; set; } = new();
        public List<BreakdownDto> ByPackage { get; set; } = new();
    }

    public class DailyRevenueDto
    {
        public DateOnly Date { get; set; } // ngày Việt Nam
        public decimal Revenue { get; set; }
        public int Count { get; set; }
    }

    public class BreakdownDto
    {
        public string Key { get; set; } = string.Empty;   // mã phương thức / mã gói
        public string Label { get; set; } = string.Empty; // tên hiển thị
        public decimal Revenue { get; set; }
        public int Count { get; set; }
    }

    // ── Danh sách giao dịch (GET api/admin/payments/transactions) ────
    public class AdminTransactionDto
    {
        public long OrderCode { get; set; }
        public string UserEmail { get; set; } = string.Empty;
        public string UserDisplayName { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string PackageName { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? FailureReason { get; set; }
        public string? GatewayTransactionId { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? PaidAt { get; set; }
    }

    public class PagedResult<T>
    {
        public List<T> Items { get; set; } = new();
        public int Total { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
    }
}
