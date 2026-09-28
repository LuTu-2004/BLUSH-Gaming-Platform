namespace Blush.Api.DataAccess.Entities
{
    // Bảng [UserSubscriptions] - mỗi lần mua/gia hạn VIP là 1 dòng
    public class UserSubscription
    {
        public int Id { get; set; }
        public Guid UserId { get; set; }
        public int VipPackageId { get; set; }
        public Guid? TransactionId { get; set; } // null = Admin cấp thủ công
        public DateTime StartAt { get; set; }
        public DateTime EndAt { get; set; }
        public DateTime CreatedAt { get; set; }

        public VipPackage VipPackage { get; set; } = null!;
    }
}
