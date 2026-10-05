namespace Blush.Api.DataAccess.Entities
{
    // Bảng [Hobbies] - danh sách sở thích có sẵn
    public class Hobby
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    // Bảng [UserHobbies] - người dùng chọn sở thích nào
    public class UserHobby
    {
        public Guid UserId { get; set; }
        public int HobbyId { get; set; }

        public Hobby Hobby { get; set; } = null!;
    }
}
