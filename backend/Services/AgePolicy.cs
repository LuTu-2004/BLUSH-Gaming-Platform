namespace Blush.Api.Services
{
    // Quy định độ tuổi tối thiểu dùng BLUSH.
    // 16 tuổi: mốc của Nghị định 13/2023 (dưới 16 tuổi phải có đồng ý của cha mẹ khi xử lý dữ liệu cá nhân).
    // Muốn đổi mức tuổi: sửa MinimumAge ở đây + AppConfig.minimumAge bên Flutter (chỉ để báo lỗi sớm trên app).
    public static class AgePolicy
    {
        public const int MinimumAge = 16;

        public static bool IsOldEnough(DateOnly dateOfBirth, DateOnly today) =>
            dateOfBirth <= today.AddYears(-MinimumAge);
    }
}
