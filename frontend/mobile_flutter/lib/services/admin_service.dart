import '../api/api_client.dart';
import '../models/admin_model.dart';
import 'auth_service.dart';

/// Gọi API khu quản trị (backend/Controllers/AdminController.cs, chỉ role Admin).
/// Dùng: `AdminService(context.read<AuthService>())`
class AdminService {
  static const pageSize = 20;

  final AuthService auth;

  AdminService(this.auth);

  ApiClient get _api => auth.api;

  Future<PaymentSummary> getPaymentSummary({int days = 30}) async =>
      PaymentSummary.fromJson(await _api.get('admin/payments/summary?days=$days') as Map<String, dynamic>);

  /// [status], [method] null = tất cả
  Future<AdminTransactionPage> getTransactions({String? status, String? method, String search = '', int page = 1}) async {
    final query = [
      'page=$page',
      'pageSize=$pageSize',
      if (status != null) 'status=$status',
      if (method != null) 'method=$method',
      if (search.trim().isNotEmpty) 'search=${Uri.encodeQueryComponent(search.trim())}',
    ].join('&');
    return AdminTransactionPage.fromJson(await _api.get('admin/payments/transactions?$query') as Map<String, dynamic>);
  }

  /// Xác nhận đã nhận tiền chuyển khoản VietQR
  Future<AdminTransaction> confirmBankTransfer(int orderCode) async =>
      AdminTransaction.fromJson(await _api.post('admin/payments/transactions/$orderCode/confirm') as Map<String, dynamic>);

  /// AI phân tích phong cách chơi cho hồ sơ cũ chưa phân tích. Trả về lời nhắn kết quả.
  Future<String> analyzePlaystyles() async => (await _api.post('admin/ai/playstyles'))['message'] as String;

  /// [role], [status] null = tất cả
  Future<AdminUserPage> getUsers({String? role, String? status, String search = '', int page = 1}) async {
    final query = [
      'page=$page',
      'pageSize=$pageSize',
      if (role != null) 'role=$role',
      if (status != null) 'status=$status',
      if (search.trim().isNotEmpty) 'search=${Uri.encodeQueryComponent(search.trim())}',
    ].join('&');
    return AdminUserPage.fromJson(await _api.get('admin/users?$query') as Map<String, dynamic>);
  }

  /// [status] = Active (mở khóa) | Suspended (cần [suspendDays]) | Banned
  Future<AdminUser> setUserStatus(String userId, String status, {int? suspendDays}) async => AdminUser.fromJson(
      await _api.post('admin/users/$userId/status', {'status': status, if (suspendDays != null) 'suspendDays': suspendDays}) as Map<String, dynamic>);

  Future<AdminUser> setUserRole(String userId, String role) async =>
      AdminUser.fromJson(await _api.post('admin/users/$userId/role', {'role': role}) as Map<String, dynamic>);
}
