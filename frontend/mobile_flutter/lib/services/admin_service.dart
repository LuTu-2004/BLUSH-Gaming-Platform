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
}
