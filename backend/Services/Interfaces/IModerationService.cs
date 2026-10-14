using Blush.Api.Dtos;

namespace Blush.Api.Services.Interfaces
{
    // Báo cáo vi phạm (người chơi gửi, Staff xử lý) + câu hỏi phá băng (Staff quản lý)
    public interface IModerationService
    {
        List<OptionDto> GetReportReasons();
        Task<ServiceResult<MessageResponse>> CreateReportAsync(Guid reporterId, CreateReportRequest request);

        /// [status] null = tất cả, Pending / Resolved
        Task<ReportListDto> GetReportsAsync(string? status, int page, int pageSize);
        Task<ServiceResult<ReportDto>> ResolveReportAsync(Guid staffId, int reportId, ResolveReportRequest request);
        /// AI chấm các báo cáo đang chờ chưa có điểm (gửi lúc AI lỗi / trước khi có tính năng)
        Task<MessageResponse> AiScorePendingReportsAsync();

        List<OptionDto> GetIceBreakerCategories();
        Task<List<IceBreakerDto>> GetIceBreakersAsync();
        Task<ServiceResult<IceBreakerDto>> CreateIceBreakerAsync(CreateIceBreakerRequest request);
        Task<ServiceResult<IceBreakerDto>> SetIceBreakerActiveAsync(int id, bool isActive);
        Task<ServiceResult<MessageResponse>> DeleteIceBreakerAsync(int id);
    }
}
