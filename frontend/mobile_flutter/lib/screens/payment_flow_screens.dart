import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../models/payment_model.dart';
import '../services/analytics.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/payment_widgets.dart';
import '../widgets/ui.dart';
import 'payment_history_screen.dart';

// ============================================================
// CÁC BƯỚC SAU KHI BẤM "THANH TOÁN" (mở từ checkout_screen.dart)
//   BankTransferScreen   - quét VietQR chuyển khoản (PayOS khi chạy thật, QR mẫu + nút giả lập ở Mock), app tự hỏi trạng thái
//   PaymentResultScreen  - kết quả: thành công / thất bại / đã hủy
// ============================================================

/// Tên hiển thị của phương thức (MoMo / VNPay / ZaloPay đã bỏ, chỉ còn để hiện giao dịch cũ)
String paymentMethodName(String method) => switch (method) {
      'MoMo' => 'Ví MoMo',
      'VNPay' => 'VNPay',
      'ZaloPay' => 'Ví ZaloPay',
      'VietQR' => 'Chuyển khoản VietQR',
      _ => method,
    };

/// Chuyển sang màn kết quả (thay thế màn hiện tại để "Thử lại" quay về màn chọn phương thức)
void _showResult(BuildContext context, PaymentTransaction transaction) {
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentResultScreen(transaction: transaction)));
}

/// Hỏi lại trước khi hủy giao dịch. Trả về giao dịch sau khi hủy, null nếu không hủy.
Future<PaymentTransaction?> _confirmCancel(BuildContext context, PaymentService service, int orderCode) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hủy giao dịch?'),
      content: const Text('Bạn có thể chọn lại gói hoặc phương thức khác sau khi hủy.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tiếp tục thanh toán')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy giao dịch')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;
  try {
    return await service.cancel(orderCode);
  } on ApiException catch (e) {
    if (context.mounted) showErrorSnack(context, e.message);
    return null;
  }
}

/// 1 dòng "nhãn ....... giá trị", có thể kèm nút sao chép
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.copyable = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: text.titleSmall?.copyWith(color: valueColor)),
          ),
          if (copyable)
            IconButton(
              tooltip: 'Sao chép',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                showSuccessSnack(context, 'Đã sao chép $label');
              },
            ),
        ],
      ),
    );
  }
}

// ── Chuyển khoản VietQR ─────────────────────────────────────────────
class BankTransferScreen extends StatefulWidget {
  final CheckoutResult checkout;

  const BankTransferScreen({super.key, required this.checkout});

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> with WidgetsBindingObserver, TransactionPolling<BankTransferScreen> {
  @override
  late final PaymentService paymentService = PaymentService(context.read<AuthService>());

  @override
  int get pollingOrderCode => widget.checkout.orderCode;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    startPolling();
  }

  @override
  void onTransactionFinished(PaymentTransaction transaction) => _showResult(context, transaction);

  // Chế độ demo: giả lập ngân hàng báo đã nhận tiền
  Future<void> _simulateReceived() async {
    setState(() => _busy = true);
    try {
      stopPolling();
      final transaction = await paymentService.completeMock(widget.checkout.orderCode, success: true);
      if (mounted) _showResult(context, transaction);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final transaction = await _confirmCancel(context, paymentService, widget.checkout.orderCode);
    if (transaction != null && mounted) {
      stopPolling();
      _showResult(context, transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final checkout = widget.checkout;
    final bank = checkout.bankTransfer;

    return Scaffold(
      appBar: AppBar(title: const Text('Chuyển khoản VietQR')),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Quét mã bằng app ngân hàng bất kỳ', textAlign: TextAlign.center, style: text.titleSmall),
                const SizedBox(height: AppSpace.md),
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    padding: const EdgeInsets.all(AppSpace.sm),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)),
                    // PayOS: tự vẽ QR từ chuỗi (không cần mạng). Mock: ảnh QR tĩnh từ img.vietqr.io
                    child: checkout.qrData != null
                        ? QrImageView(data: checkout.qrData!, padding: EdgeInsets.zero, backgroundColor: Colors.white)
                        : checkout.qrImageUrl == null
                            ? const Icon(Icons.qr_code_2, size: 160, color: Colors.black)
                            : Image.network(
                                checkout.qrImageUrl!,
                                fit: BoxFit.contain,
                                loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Text('Không tải được mã QR.\nHãy chuyển khoản theo thông tin bên dưới.',
                                      textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                if (bank != null) ...[
                  _InfoRow(label: 'Ngân hàng', value: bank.bankName),
                  _InfoRow(label: 'Số tài khoản', value: bank.accountNo, copyable: true),
                  _InfoRow(label: 'Chủ tài khoản', value: bank.accountName),
                ],
                _InfoRow(label: 'Số tiền', value: formatVnd(checkout.amount), valueColor: ThemeService.green),
                if (bank != null)
                  _InfoRow(label: 'Nội dung', value: bank.content, copyable: true, valueColor: t.isDark ? ThemeService.accentLight : ThemeService.accent),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            checkout.isMock
                ? 'Chế độ demo: đây là tài khoản mẫu, đừng chuyển tiền thật.'
                : 'Quét mã là đủ, app ngân hàng tự điền số tiền và nội dung. Nếu nhập tay, ghi đúng nội dung để gói được kích hoạt.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: checkout.isMock ? ThemeService.yellow : null),
          ),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text('Đang chờ ngân hàng xác nhận...', style: text.bodyMedium)),
                PaymentCountdown(expiresAt: checkout.expiresAt, style: text.labelMedium?.copyWith(color: t.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          if (checkout.isMock) ...[
            ElevatedButton.icon(
              onPressed: _busy ? null : _simulateReceived,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Giả lập: ngân hàng đã nhận tiền'),
            ),
            const SizedBox(height: AppSpace.sm),
          ] else if (checkout.paymentUrl != null) ...[
            // Trang thanh toán PayOS: có nút mở thẳng app ngân hàng trên điện thoại
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(checkout.paymentUrl!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Mở trang thanh toán PayOS'),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          OutlinedButton(onPressed: _busy ? null : _cancel, child: const Text('Hủy giao dịch')),
        ],
      ),
    );
  }
}

// ── Kết quả ─────────────────────────────────────────────────────────
class PaymentResultScreen extends StatefulWidget {
  final PaymentTransaction transaction;

  const PaymentResultScreen({super.key, required this.transaction});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  @override
  void initState() {
    super.initState();
    // Thành công -> lấy lại thông tin user để cả app thấy VIP mới
    if (widget.transaction.isPaid) {
      final tx = widget.transaction;
      Analytics.purchase(orderCode: tx.orderCode, packageCode: tx.packageCode, amount: tx.amount);
      context.read<AuthService>().refreshUser().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tx = widget.transaction;
    final (icon, color, title, message) = switch (tx.status) {
      PaymentTransaction.paid => (
          Icons.check_circle,
          ThemeService.green,
          'Thanh toán thành công',
          '${tx.packageName} đã được kích hoạt cho tài khoản của bạn.'
        ),
      PaymentTransaction.failed => (
          Icons.error,
          ThemeService.red,
          'Thanh toán thất bại',
          tx.failureReason ?? 'Giao dịch không thành công. Bạn chưa bị trừ tiền.'
        ),
      _ => (Icons.cancel, ThemeService.yellow, 'Giao dịch đã hủy', tx.failureReason ?? 'Giao dịch đã được hủy.'),
    };

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Kết quả thanh toán')),
      body: PageBody(
        children: [
          const SizedBox(height: AppSpace.xl),
          Icon(icon, color: color, size: 72),
          const SizedBox(height: AppSpace.lg),
          Text(title, textAlign: TextAlign.center, style: text.headlineSmall),
          const SizedBox(height: AppSpace.sm),
          Text(message, textAlign: TextAlign.center, style: text.bodyMedium),
          const SizedBox(height: AppSpace.xl),
          AppCard(
            child: Column(
              children: [
                _InfoRow(label: 'Gói', value: tx.packageName),
                _InfoRow(label: 'Số tiền', value: formatVnd(tx.amount)),
                _InfoRow(label: 'Phương thức', value: paymentMethodName(tx.method)),
                _InfoRow(label: 'Mã đơn', value: '#${tx.orderCode}'),
                if (tx.paidAt != null) _InfoRow(label: 'Thời gian', value: formatDateTime(tx.paidAt!)),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          if (!tx.isPaid) ...[
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Thử lại')),
            const SizedBox(height: AppSpace.sm),
          ],
          (tx.isPaid ? ElevatedButton.new : OutlinedButton.new)(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('Về trang chủ'),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton.icon(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Xem lịch sử thanh toán'),
          ),
        ],
      ),
    );
  }
}
