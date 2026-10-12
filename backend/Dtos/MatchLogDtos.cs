using System.ComponentModel.DataAnnotations;

namespace Blush.Api.Dtos
{
    public class MatchLogDto
    {
        public Guid Id { get; set; }
        public string GameName { get; set; } = string.Empty;
        public string Result { get; set; } = string.Empty; // Win | Loss
        public string Status { get; set; } = string.Empty; // Pending | Confirmed | Rejected
        public ChatUserDto Reporter { get; set; } = new();
        public ChatUserDto Teammate { get; set; } = new();
        public bool CanConfirm { get; set; } // mình là đồng đội và trận đang chờ
        public DateTime CreatedAt { get; set; }
    }

    // Màn Nhật ký trận: chọn đồng đội (người đã chat cùng), chọn game + khai rank
    public class MatchOptionsDto
    {
        public List<ChatUserDto> Teammates { get; set; } = new();
        public List<GameRankDto> Games { get; set; } = new();
    }

    public class GameRankDto
    {
        public int GameId { get; set; }
        public string GameName { get; set; } = string.Empty;
        public string? Rank { get; set; }
        public List<string> Ranks { get; set; } = new(); // thấp -> cao, rỗng = game không có danh sách rank
    }

    public class CreateMatchRequest
    {
        [Required(ErrorMessage = "Vui lòng chọn đồng đội.")]
        public Guid? TeammateId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Vui lòng chọn game.")]
        public int GameId { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn kết quả.")]
        [RegularExpression("^(Win|Loss)$", ErrorMessage = "Kết quả không hợp lệ.")]
        public string Result { get; set; } = string.Empty;
    }

    public class ConfirmMatchRequest
    {
        public bool Confirm { get; set; } // false = không đúng / không chơi trận này
    }

    public class SetRankRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Vui lòng chọn game.")]
        public int GameId { get; set; }

        [MaxLength(50)]
        public string? Rank { get; set; } // null = bỏ rank
    }
}
