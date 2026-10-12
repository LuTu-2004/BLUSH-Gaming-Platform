using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Hubs;
using Blush.Api.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Chat 1-1
    // Chỉ 2 thành viên của phòng mới đọc/gửi được (người ngoài nhận 404, không lộ phòng có tồn tại).
    // Mỗi phòng mới được gắn 1 câu hỏi phá băng ngẫu nhiên (Staff quản lý ở api/staff/icebreakers).
    // ============================================================
    public class ChatService : IChatService
    {
        public const int MaxPageSize = 100;

        private readonly BlushDbContext _context;
        private readonly IHubContext<ChatHub> _hub;

        public ChatService(BlushDbContext context, IHubContext<ChatHub> hub)
        {
            _context = context;
            _hub = hub;
        }

        public async Task<List<ChatRoomDto>> GetRoomsAsync(Guid userId)
        {
            var rows = await _context.ChatRooms.AsNoTracking()
                .Where(r => r.User1Id == userId || r.User2Id == userId)
                .Where(r => !_context.UserBlocks.Any(b => (b.BlockerId == r.User1Id && b.BlockedId == r.User2Id) || (b.BlockerId == r.User2Id && b.BlockedId == r.User1Id)))
                .Select(r => new
                {
                    Room = r,
                    r.IceBreakerQuestion,
                    Last = _context.ChatMessages.Where(m => m.RoomId == r.Id).OrderByDescending(m => m.CreatedAt).FirstOrDefault(),
                    Unread = _context.ChatMessages.Count(m => m.RoomId == r.Id && m.SenderId != null && m.SenderId != userId
                        && (r.User1Id == userId
                            ? r.User1LastReadAt == null || m.CreatedAt > r.User1LastReadAt
                            : r.User2LastReadAt == null || m.CreatedAt > r.User2LastReadAt)),
                })
                .ToListAsync();

            var users = await LoadUsersAsync(rows.Select(r => r.Room.OtherOf(userId)));
            return rows
                .Select(r =>
                {
                    var dto = ToDto(r.Room, r.IceBreakerQuestion, userId, users[r.Room.OtherOf(userId)], r.Last);
                    dto.UnreadCount = r.Unread;
                    return dto;
                })
                .OrderByDescending(r => r.LastMessage?.CreatedAt ?? r.CreatedAt)
                .ToList();
        }

        public async Task<ServiceResult<ChatRoomDto>> OpenRoomAsync(Guid userId, Guid otherUserId)
        {
            if (otherUserId == userId)
            {
                return ServiceResult<ChatRoomDto>.Fail(StatusCodes.Status400BadRequest, "Bạn không thể nhắn tin cho chính mình.");
            }
            var other = await _context.Users.AsNoTracking().Where(u => u.Id == otherUserId).Select(u => new { u.Status }).FirstOrDefaultAsync();
            if (other == null || other.Status is UserStatus.Banned or UserStatus.Deleted)
            {
                return ServiceResult<ChatRoomDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người chơi!");
            }

            if (await IsBlockedAsync(userId, otherUserId))
            {
                return ServiceResult<ChatRoomDto>.Fail(StatusCodes.Status403Forbidden, "Không thể nhắn tin với người này.");
            }

            var (user1, user2) = userId.CompareTo(otherUserId) < 0 ? (userId, otherUserId) : (otherUserId, userId);
            var room = await _context.ChatRooms.FirstOrDefaultAsync(r => r.User1Id == user1 && r.User2Id == user2);
            if (room == null)
            {
                room = new ChatRoom
                {
                    Id = Guid.NewGuid(),
                    User1Id = user1,
                    User2Id = user2,
                    CreatedAt = DateTime.UtcNow,
                    // NEWID() trong SQL: lấy ngẫu nhiên 1 câu đang bật (không có câu nào thì phòng không có câu phá băng)
                    IceBreakerQuestionId = await _context.IceBreakerQuestions
                        .Where(q => q.IsActive).OrderBy(q => Guid.NewGuid()).Select(q => (int?)q.Id).FirstOrDefaultAsync(),
                };
                _context.ChatRooms.Add(room);
                try
                {
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateException)
                {
                    // 2 người cùng bấm nhắn tin cho nhau một lúc -> trùng UQ_ChatRooms_Pair, dùng phòng người kia vừa tạo
                    _context.Entry(room).State = EntityState.Detached;
                    room = await _context.ChatRooms.FirstAsync(r => r.User1Id == user1 && r.User2Id == user2);
                }
            }

            return await GetRoomAsync(userId, room.Id);
        }

        public async Task<ServiceResult<ChatRoomDto>> GetRoomAsync(Guid userId, Guid roomId)
        {
            var room = await _context.ChatRooms.AsNoTracking().Include(r => r.IceBreakerQuestion).FirstOrDefaultAsync(r => r.Id == roomId);
            if (room == null || !room.HasMember(userId) || await IsBlockedAsync(room.User1Id, room.User2Id)) return RoomNotFound<ChatRoomDto>();

            var last = await _context.ChatMessages.AsNoTracking().Where(m => m.RoomId == roomId).OrderByDescending(m => m.CreatedAt).FirstOrDefaultAsync();
            var users = await LoadUsersAsync(new[] { room.OtherOf(userId) });
            return ServiceResult<ChatRoomDto>.Ok(ToDto(room, room.IceBreakerQuestion, userId, users[room.OtherOf(userId)], last));
        }

        public async Task<ServiceResult<List<ChatMessageDto>>> GetMessagesAsync(Guid userId, Guid roomId, DateTime? before, int limit)
        {
            if (!await IsMemberAsync(userId, roomId)) return RoomNotFound<List<ChatMessageDto>>();

            limit = Math.Clamp(limit, 1, MaxPageSize);
            var query = _context.ChatMessages.AsNoTracking().Where(m => m.RoomId == roomId);
            if (before != null) query = query.Where(m => m.CreatedAt < before);

            var page = await query.OrderByDescending(m => m.CreatedAt).Take(limit).ToListAsync();
            page.Reverse(); // app vẽ từ trên (cũ) xuống dưới (mới)
            return ServiceResult<List<ChatMessageDto>>.Ok(page.Select(ToDto).ToList());
        }

        public async Task<ServiceResult<ChatMessageDto>> SendAsync(Guid userId, Guid roomId, string content)
        {
            var room = await _context.ChatRooms.AsNoTracking().FirstOrDefaultAsync(r => r.Id == roomId);
            if (room == null || !room.HasMember(userId)) return RoomNotFound<ChatMessageDto>();
            if (await IsBlockedAsync(room.User1Id, room.User2Id))
            {
                return ServiceResult<ChatMessageDto>.Fail(StatusCodes.Status403Forbidden, "Không thể gửi tin nhắn cho người này.");
            }

            content = content.Trim();
            if (content.Length == 0)
            {
                return ServiceResult<ChatMessageDto>.Fail(StatusCodes.Status400BadRequest, "Tin nhắn trống.");
            }

            var message = await AddMessageAsync(room, userId, content);
            return ServiceResult<ChatMessageDto>.Ok(message);
        }

        public async Task<ServiceResult<ChatRoomDto>> AnswerIceBreakerAsync(Guid userId, Guid roomId, string choice)
        {
            var room = await _context.ChatRooms.Include(r => r.IceBreakerQuestion).FirstOrDefaultAsync(r => r.Id == roomId);
            if (room == null || !room.HasMember(userId) || await IsBlockedAsync(room.User1Id, room.User2Id)) return RoomNotFound<ChatRoomDto>();
            var question = room.IceBreakerQuestion;
            if (question == null)
            {
                return ServiceResult<ChatRoomDto>.Fail(StatusCodes.Status400BadRequest, "Phòng này không có câu hỏi phá băng.");
            }

            var isUser1 = room.User1Id == userId;
            if ((isUser1 ? room.User1Choice : room.User2Choice) != null)
            {
                return ServiceResult<ChatRoomDto>.Fail(StatusCodes.Status400BadRequest, "Bạn đã trả lời câu này rồi.");
            }
            if (isUser1) room.User1Choice = choice; else room.User2Choice = choice;
            await _context.SaveChangesAsync();

            // Cả 2 đã trả lời -> tin hệ thống để có chuyện nói tiếp
            if (room.User1Choice != null && room.User2Choice != null)
            {
                var text = room.User1Choice == room.User2Choice
                    ? $"Hai bạn cùng chọn \"{(room.User1Choice == "A" ? question.OptionA : question.OptionB)}\". Hợp cạ rồi đó!"
                    : "Hai bạn chọn khác nhau. Thử thuyết phục đối phương xem!";
                await AddMessageAsync(room, null, text);
            }

            // Mỗi người nhận phòng theo góc nhìn của mình (lựa chọn của người kia chỉ hiện khi mình đã chọn)
            var users = await LoadUsersAsync(new[] { room.User1Id, room.User2Id });
            var last = await _context.ChatMessages.AsNoTracking().Where(m => m.RoomId == roomId).OrderByDescending(m => m.CreatedAt).FirstOrDefaultAsync();
            foreach (var memberId in new[] { room.User1Id, room.User2Id })
            {
                var view = ToDto(room, question, memberId, users[room.OtherOf(memberId)], last);
                await _hub.Clients.Group(ChatHub.UserGroup(memberId)).SendAsync("room", view);
            }
            return ServiceResult<ChatRoomDto>.Ok(ToDto(room, question, userId, users[room.OtherOf(userId)], last));
        }

        public async Task<ServiceResult<MessageResponse>> MarkReadAsync(Guid userId, Guid roomId)
        {
            var now = DateTime.UtcNow;
            var updated = await _context.ChatRooms.Where(r => r.Id == roomId && r.User1Id == userId).ExecuteUpdateAsync(s => s.SetProperty(r => r.User1LastReadAt, now))
                + await _context.ChatRooms.Where(r => r.Id == roomId && r.User2Id == userId).ExecuteUpdateAsync(s => s.SetProperty(r => r.User2LastReadAt, now));
            return updated == 0
                ? RoomNotFound<MessageResponse>()
                : ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Đã đọc." });
        }

        // Lưu tin rồi phát cho cả 2 người (kể cả người gửi: máy khác của họ cũng thấy)
        private async Task<ChatMessageDto> AddMessageAsync(ChatRoom room, Guid? senderId, string content)
        {
            var message = new ChatMessage
            {
                Id = Guid.NewGuid(),
                RoomId = room.Id,
                SenderId = senderId,
                Content = content,
                IsAiGenerated = false,
                CreatedAt = DateTime.UtcNow,
            };
            _context.ChatMessages.Add(message);
            await _context.SaveChangesAsync();

            var dto = ToDto(message);
            await _hub.Clients.Groups(ChatHub.UserGroup(room.User1Id), ChatHub.UserGroup(room.User2Id)).SendAsync("message", dto);
            return dto;
        }

        // Thành viên của phòng và 2 người chưa chặn nhau (đã chặn thì phòng coi như không còn)
        private Task<bool> IsMemberAsync(Guid userId, Guid roomId) =>
            _context.ChatRooms.AnyAsync(r => r.Id == roomId && (r.User1Id == userId || r.User2Id == userId)
                && !_context.UserBlocks.Any(b => (b.BlockerId == r.User1Id && b.BlockedId == r.User2Id) || (b.BlockerId == r.User2Id && b.BlockedId == r.User1Id)));

        private Task<bool> IsBlockedAsync(Guid a, Guid b) =>
            _context.UserBlocks.AnyAsync(x => (x.BlockerId == a && x.BlockedId == b) || (x.BlockerId == b && x.BlockedId == a));

        private async Task<Dictionary<Guid, ChatUserDto>> LoadUsersAsync(IEnumerable<Guid> ids)
        {
            var list = ids.Distinct().ToList();
            return await _context.Users.AsNoTracking()
                .Where(u => list.Contains(u.Id))
                .Select(u => new ChatUserDto
                {
                    Id = u.Id,
                    DisplayName = u.Profile != null ? u.Profile.DisplayName : u.Email,
                    AvatarEmoji = u.Profile != null ? u.Profile.AvatarEmoji : "🎮",
                    AvatarUrl = u.Profile != null ? u.Profile.AvatarUrl : null,
                })
                .ToDictionaryAsync(u => u.Id);
        }

        private static ServiceResult<T> RoomNotFound<T>() =>
            ServiceResult<T>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy phòng chat!");

        private static ChatRoomDto ToDto(ChatRoom room, IceBreakerQuestion? question, Guid viewerId, ChatUserDto other, ChatMessage? last)
        {
            ChatIceBreakerDto? iceBreaker = null;
            if (question != null)
            {
                var isUser1 = room.User1Id == viewerId;
                var mine = isUser1 ? room.User1Choice : room.User2Choice;
                var theirs = isUser1 ? room.User2Choice : room.User1Choice;
                iceBreaker = new ChatIceBreakerDto
                {
                    Question = question.QuestionTextVI,
                    OptionA = question.OptionA,
                    OptionB = question.OptionB,
                    OptionAIcon = question.OptionAIcon,
                    OptionBIcon = question.OptionBIcon,
                    MyChoice = mine,
                    TheyAnswered = theirs != null,
                    TheirChoice = mine != null ? theirs : null,
                };
            }
            return new ChatRoomDto
            {
                Id = room.Id,
                Other = other,
                IceBreaker = iceBreaker,
                LastMessage = last == null ? null : ToDto(last),
                CreatedAt = room.CreatedAt,
            };
        }

        private static ChatMessageDto ToDto(ChatMessage m) => new()
        {
            Id = m.Id,
            RoomId = m.RoomId,
            SenderId = m.SenderId,
            Content = m.Content,
            CreatedAt = m.CreatedAt,
        };
    }
}
