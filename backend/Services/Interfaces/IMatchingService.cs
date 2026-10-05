using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Gợi ý đồng đội
    // Hiện dùng RuleBasedMatchingService (tính điểm theo trọng số).
    // Muốn dùng AI: viết class mới cài interface này (VD: lấy top từ rule-based rồi nhờ Gemini
    // xếp hạng lại + viết Reason), rồi đổi 1 dòng đăng ký trong Program.cs. App không phải sửa.
    // ============================================================
    public interface IMatchingService
    {
        /// [gameId] = null: mọi game người dùng chơi; có giá trị: chỉ game đó
        Task<ServiceResult<List<MatchSuggestionDto>>> GetSuggestionsAsync(Guid userId, int? gameId, int limit);
    }
}
