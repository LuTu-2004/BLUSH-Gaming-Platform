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
  final int activeVipCount;
  final int totalUsers;
  final int newUsersInRange;
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
    required this.totalUsers,
    required this.newUsersInRange,
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
      totalUsers: json['totalUsers'] as int? ?? 0,
      newUsersInRange: json['newUsersInRange'] as int? ?? 0,
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
