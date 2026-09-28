using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    public class CheckoutRequest
    {
        // Khớp cột VipPackages.PackageCode: 'month_basic' hoặc 'month_pro'
        [Required]
        public string PlanId { get; set; } = "month_basic";
    }
}
