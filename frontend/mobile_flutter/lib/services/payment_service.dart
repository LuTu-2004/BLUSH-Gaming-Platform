import '../api/api_client.dart';
import '../models/payment_model.dart';
import 'auth_service.dart';

/// Gọi API mua gói VIP (backend/Controllers/PaymentController.cs).
/// Dùng: `PaymentService(context.read<AuthService>())`
class PaymentService {
  final AuthService auth;

  PaymentService(this.auth);

  ApiClient get _api => auth.api;

  Future<List<VipPackage>> getPackages() async =>
      (await _api.get('payment/packages') as List).map((e) => VipPackage.fromJson(e as Map<String, dynamic>)).toList();

  Future<List<PaymentMethodOption>> getMethods() async =>
      (await _api.get('payment/methods') as List).map((e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>)).toList();

  /// Tạo giao dịch. [method]: 'MoMo' | 'VietQR'
  Future<CheckoutResult> checkout({required String packageCode, required String method}) async =>
      CheckoutResult.fromJson(await _api.post('payment/checkout', {'packageCode': packageCode, 'method': method}) as Map<String, dynamic>);

  Future<PaymentTransaction> getTransaction(int orderCode) async =>
      PaymentTransaction.fromJson(await _api.get('payment/transactions/$orderCode') as Map<String, dynamic>);

  Future<List<PaymentTransaction>> getHistory() async =>
      (await _api.get('payment/transactions') as List).map((e) => PaymentTransaction.fromJson(e as Map<String, dynamic>)).toList();

  Future<PaymentTransaction> cancel(int orderCode) async =>
      PaymentTransaction.fromJson(await _api.post('payment/transactions/$orderCode/cancel') as Map<String, dynamic>);

  /// Chế độ giả lập: bấm "Xác nhận thanh toán" (success = true) hoặc giả lập lỗi (false)
  Future<PaymentTransaction> completeMock(int orderCode, {required bool success}) async => PaymentTransaction.fromJson(
        await _api.post('payment/mock/$orderCode/complete', {'success': success}) as Map<String, dynamic>,
      );
}
