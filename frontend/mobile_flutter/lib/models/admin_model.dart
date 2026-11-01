// Khớp backend/Dtos/AdminPaymentDtos.cs
import 'payment_model.dart';

class DailyRevenue {
  final DateTime date; // ngày Việt Nam
  final int revenue;
  final int count;

  const DailyRevenue(this.date, this.revenue, this.count);

  factory DailyRevenue.fromJson(Map<String, dynamic> json) =>
      DailyRevenue(DateTime.parse(json['date'] as String), (json['revenue'] as num).round(), json['count'] as int? ?? 0);
}

/// Doanh thu theo 1 nhóm (phương thức / gói)
class RevenueBreakdown {
  final String key;
  final String label;
  final int revenue;
  final int count;

  const RevenueBreakdown(this.key, this.label, this.revenue, this.count);

  factory RevenueBreakdown.fromJson(Map<String, dynamic> json) =>
      RevenueBreakdown(json['key'] as String, json['label'] as String, (json['revenue'] as num).round(), json['count'] as int? ?? 0);
}

/// GET api/admin/payments/summary
class PaymentSummary {
  final int days;
  final int revenueToday;
  final int revenueThisMonth;
  final int revenueInRange;
  final int transactionCount;
  final int paidCount;
  final int pendingCount;
  final double? successRate; // 0-100, null = chưa có giao dịch kết thúc
  final int activeVipCount; // gamer có gói VIP còn hạn
  final int activeVipGiftedCount; // trong số đó: được tặng, không qua giao dịch
  final int totalUsers;
  final int newUsersInRange;
  // Hoạt động trong khoảng (sức khỏe sản phẩm)
  final int activeGamersInRange; // gamer có đăng nhập
  final int chatsStartedInRange; // lượt bắt chuyện (phòng chat mới)
  final int messagesInRange; // tin nhắn người dùng gửi
  final int matchesInRange; // trận đấu ghi cùng đồng đội
  final int confirmedMatchesInRange; // trong số đó: đồng đội đã xác nhận
  final List<DailyRevenue> daily;
  final List<RevenueBreakdown> byMethod;
  final List<RevenueBreakdown> byPackage;

  const PaymentSummary({
    required this.days,
    required this.revenueToday,
    required this.revenueThisMonth,
    required this.revenueInRange,
    required this.transactionCount,
    required this.paidCount,
    required this.pendingCount,
    required this.successRate,
    required this.activeVipCount,
    this.activeVipGiftedCount = 0,
    required this.totalUsers,
    required this.newUsersInRange,
    this.activeGamersInRange = 0,
    this.chatsStartedInRange = 0,
    this.messagesInRange = 0,
    this.matchesInRange = 0,
    this.confirmedMatchesInRange = 0,
    required this.daily,
    required this.byMethod,
    required this.byPackage,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List? ?? const []).map((e) => parse(e as Map<String, dynamic>)).toList();
    int money(String key) => (json[key] as num? ?? 0).round();
    return PaymentSummary(
      days: json['days'] as int? ?? 30,
      revenueToday: money('revenueToday'),
      revenueThisMonth: money('revenueThisMonth'),
      revenueInRange: money('revenueInRange'),
      transactionCount: json['transactionCount'] as int? ?? 0,
      paidCount: json['paidCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble(),
      activeVipCount: json['activeVipCount'] as int? ?? 0,
      activeVipGiftedCount: json['activeVipGiftedCount'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
      newUsersInRange: json['newUsersInRange'] as int? ?? 0,
      activeGamersInRange: json['activeGamersInRange'] as int? ?? 0,
      chatsStartedInRange: json['chatsStartedInRange'] as int? ?? 0,
      messagesInRange: json['messagesInRange'] as int? ?? 0,
      matchesInRange: json['matchesInRange'] as int? ?? 0,
      confirmedMatchesInRange: json['confirmedMatchesInRange'] as int? ?? 0,
      daily: list('daily', DailyRevenue.fromJson),
      byMethod: list('byMethod', RevenueBreakdown.fromJson),
      byPackage: list('byPackage', RevenueBreakdown.fromJson),
    );
  }
}

/// 1 dòng trong danh sách giao dịch của Admin
class AdminTransaction {
  final int orderCode;
  final String userEmail;
  final String userDisplayName;
  final int amount;
  final String packageName;
  final String method;
  final String status;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const AdminTransaction({
    required this.orderCode,
    required this.userEmail,
    required this.userDisplayName,
    required this.amount,
    required this.packageName,
    required this.method,
    required this.status,
    this.failureReason,
    this.createdAt,
    this.paidAt,
  });

  /// Chuyển khoản VietQR chưa xác nhận -> Admin đối soát rồi bấm xác nhận
  bool get canConfirmManually => (method == 'VietQR' || method == 'VietQR_PayOS') && status != PaymentTransaction.paid;

  factory AdminTransaction.fromJson(Map<String, dynamic> json) => AdminTransaction(
        orderCode: json['orderCode'] as int,
        userEmail: json['userEmail'] as String? ?? '',
        userDisplayName: json['userDisplayName'] as String? ?? '',
        amount: (json['amount'] as num).round(),
        packageName: json['packageName'] as String? ?? '',
        method: json['method'] as String? ?? '',
        status: json['status'] as String? ?? '',
        failureReason: json['failureReason'] as String?,
        createdAt: parseServerDate(json['createdAt']),
        paidAt: parseServerDate(json['paidAt']),
      );
}

class AdminTransactionPage {
  final List<AdminTransaction> items;
  final int total;
  final int page;

  const AdminTransactionPage(this.items, this.total, this.page);

  factory AdminTransactionPage.fromJson(Map<String, dynamic> json) => AdminTransactionPage(
        (json['items'] as List).map((e) => AdminTransaction.fromJson(e as Map<String, dynamic>)).toList(),
        json['total'] as int? ?? 0,
        json['page'] as int? ?? 1,
      );
}

// ── Quản lý người dùng (backend/Dtos/AdminUserDtos.cs) ─────────────────

class AdminUser {
  static const active = 'Active';
  static const suspended = 'Suspended';
  static const banned = 'Banned';
  static const deleted = 'Deleted'; // người dùng tự xóa tài khoản

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String role; // 'User' | 'Staff' | 'Admin'
  final String status; // Active | Suspended | Banned (tạm khóa hết hạn thì backend trả Active)
  final DateTime? suspendedUntil;
  final bool isVip;
  final int level;
  final DateTime? lastLoginAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.status,
    this.suspendedUntil,
    this.isVip = false,
    this.level = 1,
    this.lastLoginAt,
  });

  bool get isLocked => status != active;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String? ?? 'User',
        status: json['status'] as String? ?? active,
        suspendedUntil: parseServerDate(json['suspendedUntil']),
        isVip: json['isVip'] as bool? ?? false,
        level: json['level'] as int? ?? 1,
        lastLoginAt: parseServerDate(json['lastLoginAt']),
      );
}

/// GET api/admin/users: 1 trang danh sách + số liệu KPI (tính trên toàn bộ người dùng)
class AdminUserPage {
  final List<AdminUser> items;
  final int total;
  final int page;
  final int totalUsers;
  final int vipUsers;
  final int lockedUsers;

  const AdminUserPage({required this.items, required this.total, required this.page, this.totalUsers = 0, this.vipUsers = 0, this.lockedUsers = 0});

  factory AdminUserPage.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    return AdminUserPage(
      items: (json['items'] as List).map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalUsers: stats['total'] as int? ?? 0,
      vipUsers: stats['vip'] as int? ?? 0,
      lockedUsers: stats['locked'] as int? ?? 0,
    );
  }
}

// ── Lịch sử đánh giá app (backend/Dtos/RatingDtos.cs) ──────────────────

/// 1 đánh giá trong trang Lịch sử đánh giá
class AdminRating {
  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final int stars;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminRating({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.stars,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  /// Người dùng đã sửa đánh giá sau lần gửi đầu
  bool get isEdited => createdAt != null && updatedAt != null && updatedAt!.difference(createdAt!).inMinutes >= 1;

  factory AdminRating.fromJson(Map<String, dynamic> json) => AdminRating(
        userId: json['userId'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        stars: json['stars'] as int,
        comment: json['comment'] as String?,
        createdAt: parseServerDate(json['createdAt']),
        updatedAt: parseServerDate(json['updatedAt']),
      );
}

/// Số liệu trên toàn bộ đánh giá (không theo bộ lọc)
class AdminRatingStats {
  final int count;
  final double? average; // null = chưa có đánh giá
  final List<int> byStars; // [0] = số lượt 1 sao ... [4] = 5 sao

  const AdminRatingStats({this.count = 0, this.average, this.byStars = const [0, 0, 0, 0, 0]});

  /// Số lượt đánh giá [stars] sao
  int countOf(int stars) => byStars[stars - 1];

  factory AdminRatingStats.fromJson(Map<String, dynamic> json) => AdminRatingStats(
        count: json['count'] as int? ?? 0,
        average: (json['average'] as num?)?.toDouble(),
        byStars: (json['byStars'] as List? ?? const [0, 0, 0, 0, 0]).map((e) => e as int).toList(),
      );
}

/// GET api/admin/ratings: 1 trang danh sách + số liệu tổng
class AdminRatingPage {
  final List<AdminRating> items;
  final int total;
  final int page;
  final AdminRatingStats stats;

  const AdminRatingPage({required this.items, required this.total, required this.page, this.stats = const AdminRatingStats()});

  factory AdminRatingPage.fromJson(Map<String, dynamic> json) => AdminRatingPage(
        items: (json['items'] as List).map((e) => AdminRating.fromJson(e as Map<String, dynamic>)).toList(),
        total: json['total'] as int? ?? 0,
        page: json['page'] as int? ?? 1,
        stats: AdminRatingStats.fromJson(json['stats'] as Map<String, dynamic>? ?? const {}),
      );
}

// ── Nguồn người dùng (GET api/admin/acquisition, backend/Dtos/AdminUserDtos.cs) ──

/// Gamer biết BLUSH qua đâu: đủ mọi nguồn (chưa ai chọn = 0), nhiều nhất trước
class AcquisitionStats {
  final int totalUsers; // tổng gamer
  final int answered; // số gamer đã trả lời
  final List<RevenueBreakdown> sources; // dùng key / label / count, revenue = 0

  const AcquisitionStats({required this.totalUsers, required this.answered, required this.sources});

  factory AcquisitionStats.fromJson(Map<String, dynamic> json) => AcquisitionStats(
        totalUsers: json['totalUsers'] as int? ?? 0,
        answered: json['answered'] as int? ?? 0,
        sources: (json['sources'] as List? ?? const [])
            .map((e) => e as Map<String, dynamic>)
            .map((e) => RevenueBreakdown(e['key'] as String, e['label'] as String, 0, e['count'] as int? ?? 0))
            .toList(),
      );
}

// ── Google Analytics (GET api/admin/analytics, backend/Dtos/AnalyticsDtos.cs) ──

class AnalyticsSource {
  final String source; // facebook, google, (direct)...
  final int sessions;
  final int users;
  final int downloads;

  const AnalyticsSource(this.source, this.sessions, this.users, this.downloads);

  factory AnalyticsSource.fromJson(Map<String, dynamic> json) =>
      AnalyticsSource(json['source'] as String? ?? '', json['sessions'] as int? ?? 0, json['users'] as int? ?? 0, json['downloads'] as int? ?? 0);
}

class AnalyticsEvent {
  final String name;
  final String label;
  final int count;

  const AnalyticsEvent(this.name, this.label, this.count);

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) =>
      AnalyticsEvent(json['name'] as String? ?? '', json['label'] as String? ?? '', json['count'] as int? ?? 0);
}

class AnalyticsDaily {
  final DateTime date;
  final int webUsers;
  final int appUsers;

  const AnalyticsDaily(this.date, this.webUsers, this.appUsers);

  factory AnalyticsDaily.fromJson(Map<String, dynamic> json) =>
      AnalyticsDaily(DateTime.parse(json['date'] as String), json['webUsers'] as int? ?? 0, json['appUsers'] as int? ?? 0);
}

/// Số liệu landing page (luồng Web) + app Android từ cùng 1 GA property.
/// [available] = false: chưa cấu hình / GA từ chối -> hiện [message] hướng dẫn thay cho số liệu.
class AdminAnalytics {
  final bool available;
  final String? message;
  final String? propertyId;
  final int days;
  final DateTime? fetchedAt;
  final int realtimeUsers;
  final int webUsers;
  final int webSessions;
  final int webPageViews;
  final int downloadClicks;
  final List<AnalyticsSource> sources;
  final int appUsers;
  final int appNewUsers;
  final List<AnalyticsEvent> appEvents;
  final List<AnalyticsDaily> daily;

  const AdminAnalytics({
    required this.available,
    this.message,
    this.propertyId,
    this.days = 30,
    this.fetchedAt,
    this.realtimeUsers = 0,
    this.webUsers = 0,
    this.webSessions = 0,
    this.webPageViews = 0,
    this.downloadClicks = 0,
    this.sources = const [],
    this.appUsers = 0,
    this.appNewUsers = 0,
    this.appEvents = const [],
    this.daily = const [],
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List? ?? const []).map((e) => parse(e as Map<String, dynamic>)).toList();
    return AdminAnalytics(
      available: json['available'] as bool? ?? false,
      message: json['message'] as String?,
      propertyId: json['propertyId'] as String?,
      days: json['days'] as int? ?? 30,
      fetchedAt: parseServerDate(json['fetchedAt']),
      realtimeUsers: json['realtimeUsers'] as int? ?? 0,
      webUsers: json['webUsers'] as int? ?? 0,
      webSessions: json['webSessions'] as int? ?? 0,
      webPageViews: json['webPageViews'] as int? ?? 0,
      downloadClicks: json['downloadClicks'] as int? ?? 0,
      sources: list('sources', AnalyticsSource.fromJson),
      appUsers: json['appUsers'] as int? ?? 0,
      appNewUsers: json['appNewUsers'] as int? ?? 0,
      appEvents: list('appEvents', AnalyticsEvent.fromJson),
      daily: list('daily', AnalyticsDaily.fromJson),
    );
  }
}
