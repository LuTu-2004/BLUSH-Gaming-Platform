namespace Blush.Api.Dtos
{
    public class QuestResultDto
    {
        public string Message { get; set; } = string.Empty;
        public int AddedCoins { get; set; }
        public int AddedExp { get; set; }
        public UserDto User { get; set; } = null!;
    }
}
