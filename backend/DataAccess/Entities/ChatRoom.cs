namespace Blush.Api.DataAccess.Entities
{
    // Bảng [ChatRooms] - phòng chat 1-1. Luôn lưu User1Id < User2Id (so sánh Guid trong C#)
    // nên UQ_ChatRooms_Pair chặn được phòng trùng theo cả 2 chiều.
    public class ChatRoom
    {
        public Guid Id { get; set; }
        public int? ZoneId { get; set; }
        public Guid User1Id { get; set; }
        public Guid User2Id { get; set; }
        public int? IceBreakerQuestionId { get; set; }
        public string? User1Choice { get; set; } // 'A' | 'B', null = chưa trả lời câu phá băng
        public string? User2Choice { get; set; }
        public string Status { get; set; } = "Active";
        public DateTime CreatedAt { get; set; }

        public IceBreakerQuestion? IceBreakerQuestion { get; set; }

        public bool HasMember(Guid userId) => User1Id == userId || User2Id == userId;
        public Guid OtherOf(Guid userId) => User1Id == userId ? User2Id : User1Id;
    }

    // Bảng [Messages]
    public class ChatMessage
    {
        public Guid Id { get; set; }
        public Guid RoomId { get; set; }
        public Guid? SenderId { get; set; } // null = tin hệ thống / trợ lý AI
        public string Content { get; set; } = string.Empty;
        public bool IsAiGenerated { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
