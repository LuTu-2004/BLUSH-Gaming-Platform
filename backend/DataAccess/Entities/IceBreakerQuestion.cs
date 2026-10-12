namespace Blush.Api.DataAccess.Entities
{
    // Bảng [IceBreakerQuestions] - câu hỏi 2 lựa chọn để 2 người mới ghép đội bắt chuyện (Staff quản lý)
    public class IceBreakerQuestion
    {
        public int Id { get; set; }
        public string Category { get; set; } = string.Empty; // IceBreakerCategory
        public string QuestionTextVI { get; set; } = string.Empty;
        public string? QuestionTextEN { get; set; }
        public string OptionA { get; set; } = string.Empty;
        public string OptionB { get; set; } = string.Empty;
        public string OptionAIcon { get; set; } = "🛡️";
        public string OptionBIcon { get; set; } = "👑";
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; }
    }

    public static class IceBreakerCategory
    {
        // Mã lưu DB -> nhãn tiếng Việt cho app
        public static readonly IReadOnlyDictionary<string, string> Labels = new Dictionary<string, string>
        {
            ["Strategy"] = "Chiến thuật",
            ["Lobby Style"] = "Phong cách sảnh",
            ["Team Role"] = "Vai trò trong team",
        };
    }
}
