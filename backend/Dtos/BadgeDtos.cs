namespace Blush.Api.Dtos
{
    public class BadgeDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Icon { get; set; } = string.Empty;
        public string? Description { get; set; } // điều kiện nhận
        public bool Earned { get; set; }
        public DateTime? EarnedAt { get; set; }
    }
}
