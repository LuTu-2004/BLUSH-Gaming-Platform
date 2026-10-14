using Blush.Api.DataAccess;
using Blush.Api.DataAccess.Entities;
using Blush.Api.Dtos;
using Blush.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Blush.Api.Services.Implementations
{
    // ============================================================
    // LAYER 2: BUSINESS LOGIC - Kiểm duyệt
    //   Báo cáo vi phạm: người chơi gửi -> Staff cảnh báo / tạm khóa 3 ngày / bỏ qua
    //   AI chấm mức vi phạm để xếp báo cáo nặng lên đầu; báo cáo AI tạo khi tạm ẩn bài viết / bình luận:
    //   Staff bỏ qua -> nội dung hiện lại, cảnh báo / tạm khóa -> gỡ nội dung. AI không tự xử lý ai cả.
    //   Câu hỏi phá băng: Staff thêm, bật/tắt, xóa (câu đã dùng trong phòng chat thì chỉ tắt được)
    // ============================================================
    public class ModerationService : IModerationService
    {
        private readonly BlushDbContext _context;
        private readonly INotificationService _notifications;
        private readonly IContentModerator _moderator;

        /// Từ điểm này trở lên: AI thấy rõ vi phạm nặng -> lên đầu danh sách chờ
        public const int AiPriorityScore = 70;

        public ModerationService(BlushDbContext context, INotificationService notifications, IContentModerator moderator)
        {
            _context = context;
            _notifications = notifications;
            _moderator = moderator;
        }

        // ─────────────────────────── BÁO CÁO VI PHẠM ───────────────────────────

        public List<OptionDto> GetReportReasons() =>
            ReportReason.All.Select(r => new OptionDto { Code = r.Code, Label = r.Label }).ToList();

        public async Task<ServiceResult<MessageResponse>> CreateReportAsync(Guid reporterId, CreateReportRequest request)
        {
            var reportedId = request.ReportedUserId!.Value;
            var reason = ReportReason.Find(request.ReasonCode);
            if (reason == null)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Lý do báo cáo không hợp lệ.");
            }
            if (reportedId == reporterId)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Bạn không thể tự báo cáo chính mình.");
            }
            if (!await _context.Users.AnyAsync(u => u.Id == reportedId && u.Status != UserStatus.Deleted))
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy người chơi!");
            }
            // Chống spam: mỗi người chỉ có 1 báo cáo đang chờ cho cùng 1 người
            if (await _context.Reports.AnyAsync(r => r.ReporterId == reporterId && r.ReportedUserId == reportedId && r.Status == ReportStatus.Pending))
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status400BadRequest, "Bạn đã báo cáo người này, Staff đang xem xét.");
            }

            var detail = request.Detail?.Trim();
            var report = new Report
            {
                ReporterId = reporterId,
                ReportedUserId = reportedId,
                Reason = string.IsNullOrEmpty(detail) ? reason.Label : $"{reason.Label}: {detail}",
                Severity = reason.Severity,
            };
            _context.Reports.Add(report);
            await _context.SaveChangesAsync();
            await _moderator.ScoreReportAsync(report.Id); // AI lỗi thì báo cáo vẫn gửi, chỉ chưa có điểm

            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Đã gửi báo cáo. Cảm ơn bạn, Staff sẽ xem xét sớm." });
        }

        public async Task<ReportListDto> GetReportsAsync(string? status, int page, int pageSize)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _context.Reports.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(status)) query = query.Where(r => r.Status == status);

            var total = await query.CountAsync();
            // Chưa xử lý lên trước; trong đó AI thấy vi phạm nặng lên đầu, rồi mức nặng theo lý do, điểm AI, mới nhất
            var items = await ToDto(query
                    .OrderBy(r => r.Status == ReportStatus.Pending ? 0 : 1)
                    .ThenBy(r => r.AiScore >= AiPriorityScore ? 0 : 1)
                    .ThenBy(r => r.Severity == ReportSeverity.High ? 0 : r.Severity == ReportSeverity.Medium ? 1 : 2)
                    .ThenByDescending(r => r.AiScore)
                    .ThenByDescending(r => r.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize))
                .ToListAsync();

            var pending = await _context.Reports.CountAsync(r => r.Status == ReportStatus.Pending);
            var all = await _context.Reports.CountAsync();
            return new ReportListDto
            {
                Items = items,
                Total = total,
                Page = page,
                PageSize = pageSize,
                Stats = new ReportStatsDto { Total = all, Pending = pending, Resolved = all - pending },
            };
        }

        public async Task<ServiceResult<ReportDto>> ResolveReportAsync(Guid staffId, int reportId, ResolveReportRequest request)
        {
            var report = await _context.Reports.AsNoTracking().FirstOrDefaultAsync(r => r.Id == reportId);
            if (report == null)
            {
                return ServiceResult<ReportDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy báo cáo!");
            }

            var target = await _context.Users.Include(u => u.Role).FirstAsync(u => u.Id == report.ReportedUserId);
            if (request.Action == ReportAction.Suspend && target.Role.RoleName != "User")
            {
                return ServiceResult<ReportDto>.Fail(StatusCodes.Status400BadRequest, "Chỉ tạm khóa được tài khoản game thủ. Hãy báo Admin nếu cần xử lý Staff/Admin.");
            }

            var now = DateTime.UtcNow;
            await using var transaction = await _context.Database.BeginTransactionAsync();

            // UPDATE có điều kiện: 2 Staff bấm cùng lúc thì chỉ 1 người xử lý được
            var updated = await _context.Reports
                .Where(r => r.Id == reportId && r.Status == ReportStatus.Pending)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(r => r.Status, ReportStatus.Resolved)
                    .SetProperty(r => r.ActionTaken, request.Action)
                    .SetProperty(r => r.ResolvedBy, staffId)
                    .SetProperty(r => r.ResolvedAt, now));
            if (updated == 0)
            {
                return ServiceResult<ReportDto>.Fail(StatusCodes.Status400BadRequest, "Báo cáo này đã được xử lý rồi.");
            }

            // Tạm khóa: không hạ mức của người đã bị khóa vĩnh viễn, không rút ngắn lần tạm khóa dài hơn đang có
            if (request.Action == ReportAction.Suspend && target.Status is UserStatus.Active or UserStatus.Suspended)
            {
                var until = now.AddDays(ReportAction.SuspendDays);
                target.Status = UserStatus.Suspended;
                target.SuspendedUntil = target.SuspendedUntil > until ? target.SuspendedUntil : until;
                target.UpdatedAt = now;
                await _context.SaveChangesAsync();
            }

            // Nội dung AI tạm ẩn: bỏ qua -> hiện lại; cảnh báo / tạm khóa -> gỡ hẳn
            var restore = request.Action == ReportAction.Dismiss;
            if (report.PostId != null)
            {
                await _context.Posts.Where(p => p.Id == report.PostId && p.RemovedAt == null).ExecuteUpdateAsync(s => restore
                    ? s.SetProperty(p => p.HeldAt, (DateTime?)null)
                    : s.SetProperty(p => p.RemovedAt, now).SetProperty(p => p.RemovedBy, staffId));
            }
            if (report.CommentId != null)
            {
                await _context.PostComments.Where(c => c.Id == report.CommentId && c.RemovedAt == null).ExecuteUpdateAsync(s => restore
                    ? s.SetProperty(c => c.HeldAt, (DateTime?)null)
                    : s.SetProperty(c => c.RemovedAt, now));
            }

            await transaction.CommitAsync();

            // Báo kết quả: người bị báo cáo (cảnh báo / tạm khóa) và người đã gửi báo cáo
            var aiHeld = report.ReporterId == null;
            var why = aiHeld ? "nội dung bạn đăng vi phạm quy tắc cộng đồng và đã bị gỡ" : report.Reason;
            if (request.Action == ReportAction.Warn)
            {
                await _notifications.NotifyAsync(report.ReportedUserId, NotificationType.Warning, "Cảnh báo từ đội kiểm duyệt BLUSH",
                    aiHeld ? $"Lý do: {why}. Tái phạm có thể bị tạm khóa tài khoản." : $"Bạn bị báo cáo: {why}. Tái phạm có thể bị tạm khóa tài khoản.");
            }
            else if (request.Action == ReportAction.Suspend)
            {
                await _notifications.NotifyAsync(report.ReportedUserId, NotificationType.Warning, $"Tài khoản bị tạm khóa {ReportAction.SuspendDays} ngày",
                    $"Lý do: {why}. Hãy giữ cộng đồng BLUSH thân thiện nhé.");
            }
            else if (aiHeld)
            {
                await _notifications.NotifyAsync(report.ReportedUserId, NotificationType.ReportResolved, "Nội dung của bạn đã hiện lại",
                    "Staff đã xem lại và không thấy vi phạm. Xin lỗi vì đã tạm ẩn nhầm.");
            }
            if (report.ReporterId is Guid reporterId)
            {
                await _notifications.NotifyAsync(reporterId, NotificationType.ReportResolved, "Báo cáo của bạn đã được xử lý",
                    request.Action == ReportAction.Dismiss
                        ? "Staff đã xem xét và chưa thấy vi phạm. Cảm ơn bạn đã báo cáo."
                        : "Staff đã xử lý người bị báo cáo. Cảm ơn bạn đã giúp cộng đồng an toàn hơn.");
            }

            return ServiceResult<ReportDto>.Ok(await ToDto(_context.Reports.AsNoTracking().Where(r => r.Id == reportId)).FirstAsync());
        }

        private IQueryable<ReportDto> ToDto(IQueryable<Report> reports) =>
            from r in reports
            join target in _context.Users on r.ReportedUserId equals target.Id
            join reporter in _context.Users on r.ReporterId equals reporter.Id into reporters
            from reporter in reporters.DefaultIfEmpty()
            join staff in _context.Users on r.ResolvedBy equals staff.Id into staffs
            from staff in staffs.DefaultIfEmpty()
            select new ReportDto
            {
                Id = r.Id,
                ReporterId = r.ReporterId,
                ReporterName = reporter == null ? null : reporter.Profile != null ? reporter.Profile.DisplayName : reporter.Email,
                ReportedUserId = r.ReportedUserId,
                ReportedUserName = target.Profile != null ? target.Profile.DisplayName : target.Email,
                ReportedUserEmail = target.Email,
                Reason = r.Reason,
                Severity = r.Severity,
                Status = r.Status,
                ActionTaken = r.ActionTaken,
                ResolvedByName = staff == null ? null : staff.Profile != null ? staff.Profile.DisplayName : staff.Email,
                ResolvedAt = r.ResolvedAt,
                CreatedAt = r.CreatedAt,
                AiScore = r.AiScore,
                AiSummary = r.AiSummary,
                ContentType = r.PostId != null ? "Post" : r.CommentId != null ? "Comment" : null,
                Content = r.PostId != null
                    ? _context.Posts.Where(p => p.Id == r.PostId).Select(p => p.Content).FirstOrDefault()
                    : _context.PostComments.Where(c => c.Id == r.CommentId).Select(c => c.Content).FirstOrDefault(),
            };

        public async Task<MessageResponse> AiScorePendingReportsAsync() =>
            new() { Message = $"AI đã chấm {await _moderator.ScorePendingReportsAsync(50)} báo cáo." };

        // ─────────────────────────── CÂU HỎI PHÁ BĂNG ───────────────────────────

        public List<OptionDto> GetIceBreakerCategories() =>
            IceBreakerCategory.Labels.Select(kv => new OptionDto { Code = kv.Key, Label = kv.Value }).ToList();

        public async Task<List<IceBreakerDto>> GetIceBreakersAsync() =>
            await _context.IceBreakerQuestions.AsNoTracking()
                .OrderByDescending(q => q.CreatedAt).ThenByDescending(q => q.Id)
                .Select(q => ToDto(q))
                .ToListAsync();

        public async Task<ServiceResult<IceBreakerDto>> CreateIceBreakerAsync(CreateIceBreakerRequest request)
        {
            if (!IceBreakerCategory.Labels.ContainsKey(request.Category))
            {
                return ServiceResult<IceBreakerDto>.Fail(StatusCodes.Status400BadRequest, "Loại câu hỏi không hợp lệ.");
            }
            var question = new IceBreakerQuestion
            {
                Category = request.Category,
                QuestionTextVI = request.Question.Trim(),
                OptionA = request.OptionA.Trim(),
                OptionB = request.OptionB.Trim(),
                CreatedAt = DateTime.UtcNow,
            };
            if (question.QuestionTextVI.Length == 0 || question.OptionA.Length == 0 || question.OptionB.Length == 0)
            {
                return ServiceResult<IceBreakerDto>.Fail(StatusCodes.Status400BadRequest, "Câu hỏi và 2 lựa chọn không được để trống.");
            }

            _context.IceBreakerQuestions.Add(question);
            await _context.SaveChangesAsync();
            return ServiceResult<IceBreakerDto>.Ok(ToDto(question));
        }

        public async Task<ServiceResult<IceBreakerDto>> SetIceBreakerActiveAsync(int id, bool isActive)
        {
            var question = await _context.IceBreakerQuestions.FindAsync(id);
            if (question == null)
            {
                return ServiceResult<IceBreakerDto>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy câu hỏi!");
            }
            question.IsActive = isActive;
            await _context.SaveChangesAsync();
            return ServiceResult<IceBreakerDto>.Ok(ToDto(question));
        }

        public async Task<ServiceResult<MessageResponse>> DeleteIceBreakerAsync(int id)
        {
            var question = await _context.IceBreakerQuestions.FindAsync(id);
            if (question == null)
            {
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status404NotFound, "Không tìm thấy câu hỏi!");
            }
            _context.IceBreakerQuestions.Remove(question);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // ChatRooms.IceBreakerQuestionId đang trỏ tới câu này (khóa ngoại) -> giữ lại để lịch sử chat không hỏng
                return ServiceResult<MessageResponse>.Fail(StatusCodes.Status409Conflict, "Câu hỏi đã được dùng trong phòng chat, hãy tắt thay vì xóa.");
            }
            return ServiceResult<MessageResponse>.Ok(new MessageResponse { Message = "Đã xóa câu hỏi." });
        }

        private static IceBreakerDto ToDto(IceBreakerQuestion q) => new()
        {
            Id = q.Id,
            Category = q.Category,
            Question = q.QuestionTextVI,
            OptionA = q.OptionA,
            OptionB = q.OptionB,
            OptionAIcon = q.OptionAIcon,
            OptionBIcon = q.OptionBIcon,
            IsActive = q.IsActive,
            CreatedAt = q.CreatedAt,
        };
    }
}
