// Khớp backend/Dtos/ModerationDtos.cs (báo cáo vi phạm + câu hỏi phá băng)
import 'payment_model.dart';

class ModerationReport {
  static const pending = 'Pending';

  final int id;
  final String? reporterName; // null = AI tạo khi tạm ẩn bài viết / bình luận
  final String reportedUserId;
  final String reportedUserName;
  final String reportedUserEmail;
  final String reason;
  final String severity; // High | Medium | Low
  final String status; // Pending | Resolved
  final String? actionTaken; // Warn | Suspend | Dismiss
  final String? resolvedByName;
  final DateTime? createdAt;
  final int? aiScore; // AI chấm mức vi phạm 0-100, null = chưa chấm
  final String? aiSummary;
  final String? contentType; // Post | Comment: nội dung AI tạm ẩn
  final String? content;

  const ModerationReport({
    required this.id,
    this.reporterName,
    required this.reportedUserId,
    required this.reportedUserName,
    this.reportedUserEmail = '',
    required this.reason,
    required this.severity,
    required this.status,
    this.actionTaken,
    this.resolvedByName,
    this.createdAt,
    this.aiScore,
    this.aiSummary,
    this.contentType,
    this.content,
  });

  bool get isPending => status == pending;
  bool get isAiFlagged => reporterName == null;

  factory ModerationReport.fromJson(Map<String, dynamic> json) => ModerationReport(
        id: json['id'] as int,
        reporterName: json['reporterName'] as String?,
        reportedUserId: json['reportedUserId'] as String? ?? '',
        reportedUserName: json['reportedUserName'] as String? ?? '',
        reportedUserEmail: json['reportedUserEmail'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        severity: json['severity'] as String? ?? 'Medium',
        status: json['status'] as String? ?? pending,
        actionTaken: json['actionTaken'] as String?,
        resolvedByName: json['resolvedByName'] as String?,
        createdAt: parseServerDate(json['createdAt']),
        aiScore: json['aiScore'] as int?,
        aiSummary: json['aiSummary'] as String?,
        contentType: json['contentType'] as String?,
        content: json['content'] as String?,
      );
}

/// GET api/staff/reports: 1 trang báo cáo + số liệu (tính trên mọi báo cáo)
class ReportPage {
  final List<ModerationReport> items;
  final int total;
  final int page;
  final int totalReports;
  final int pendingReports;
  final int resolvedReports;

  const ReportPage({required this.items, required this.total, required this.page, this.totalReports = 0, this.pendingReports = 0, this.resolvedReports = 0});

  factory ReportPage.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    return ReportPage(
      items: (json['items'] as List).map((e) => ModerationReport.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalReports: stats['total'] as int? ?? 0,
      pendingReports: stats['pending'] as int? ?? 0,
      resolvedReports: stats['resolved'] as int? ?? 0,
    );
  }
}

class IceBreaker {
  final int id;
  final String category;
  final String question;
  final String optionA;
  final String optionB;
  final String optionAIcon;
  final String optionBIcon;
  final bool isActive;

  const IceBreaker({
    required this.id,
    required this.category,
    required this.question,
    required this.optionA,
    required this.optionB,
    this.optionAIcon = '🛡️',
    this.optionBIcon = '👑',
    this.isActive = true,
  });

  factory IceBreaker.fromJson(Map<String, dynamic> json) => IceBreaker(
        id: json['id'] as int,
        category: json['category'] as String? ?? '',
        question: json['question'] as String? ?? '',
        optionA: json['optionA'] as String? ?? '',
        optionB: json['optionB'] as String? ?? '',
        optionAIcon: json['optionAIcon'] as String? ?? '🛡️',
        optionBIcon: json['optionBIcon'] as String? ?? '👑',
        isActive: json['isActive'] as bool? ?? true,
      );
}
