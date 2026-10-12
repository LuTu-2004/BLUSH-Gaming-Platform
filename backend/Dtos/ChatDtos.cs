using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    public class ChatUserDto
    {
        public Guid Id { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string AvatarEmoji { get; set; } = "🎮";
        public string? AvatarUrl { get; set; }
    }

    public class ChatMessageDto
    {
        public Guid Id { get; set; }
        public Guid RoomId { get; set; }
        public Guid? SenderId { get; set; } // null = tin hệ thống
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    // Câu hỏi phá băng của phòng, nhìn từ phía người đang xem:
    // lựa chọn của người kia chỉ hiện sau khi mình đã chọn (để không bị "ăn theo")
    public class ChatIceBreakerDto
    {
        public string Question { get; set; } = string.Empty;
        public string OptionA { get; set; } = string.Empty;
        public string OptionB { get; set; } = string.Empty;
        public string OptionAIcon { get; set; } = string.Empty;
        public string OptionBIcon { get; set; } = string.Empty;
        public string? MyChoice { get; set; }
        public bool TheyAnswered { get; set; }
        public string? TheirChoice { get; set; }
    }

    public class ChatRoomDto
    {
        public Guid Id { get; set; }
        public ChatUserDto Other { get; set; } = new();
        public ChatIceBreakerDto? IceBreaker { get; set; }
        public ChatMessageDto? LastMessage { get; set; }
        public int UnreadCount { get; set; } // tin người kia gửi mà mình chưa đọc
        public DateTime CreatedAt { get; set; }
    }

    public class OpenChatRequest
    {
        [Required(ErrorMessage = "Thiếu người nhận.")]
        public Guid? UserId { get; set; }
    }

    public class SendMessageRequest
    {
        [Required(ErrorMessage = "Tin nhắn trống.")]
        [MaxLength(2000, ErrorMessage = "Tin nhắn tối đa 2000 ký tự.")]
        public string Content { get; set; } = string.Empty;
    }

    public class IceBreakerAnswerRequest
    {
        [Required(ErrorMessage = "Vui lòng chọn A hoặc B.")]
        [RegularExpression("^(A|B)$", ErrorMessage = "Vui lòng chọn A hoặc B.")]
        public string Choice { get; set; } = string.Empty;
    }
}
