import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../models/payment_model.dart';
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
//   MockGatewayScreen    - cổng MoMo giả lập (backend chạy Payment:Mode = Mock)
//   BankTransferScreen   - quét VietQR chuyển khoản (PayOS khi chạy thật), app tự hỏi trạng thái
//   PaymentWaitingScreen - đang trả tiền trên trang/app MoMo (Sandbox/Production), app tự hỏi trạng thái
//   PaymentResultScreen  - kết quả: thành công / thất bại / đã hủy
// ============================================================

/// Tên hiển thị của phương thức
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

// ── Cổng thanh toán giả lập ─────────────────────────────────────────
class MockGatewayScreen extends StatefulWidget {
  final CheckoutResult checkout;

  const MockGatewayScreen({super.key, required this.checkout});

  @override
  State<MockGatewayScreen> createState() => _MockGatewayScreenState();
}

class _MockGatewayScreenState extends State<MockGatewayScreen> {
  late final PaymentService _service = PaymentService(context.read<AuthService>());
  bool _busy = false;

  Future<void> _complete(bool success) async {
    setState(() => _busy = true);
    try {
      final transaction = await _service.completeMock(widget.checkout.orderCode, success: success);
      if (mounted) _showResult(context, transaction);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final transaction = await _confirmCancel(context, _service, widget.checkout.orderCode);
    if (transaction != null && mounted) _showResult(context, transaction);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final checkout = widget.checkout;
    final brand = PaymentBrand.of(checkout.method);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: brand.color,
        foregroundColor: Colors.white,
        titleTextStyle: text.titleMedium?.copyWith(color: Colors.white),
        title: Text('Cổng ${paymentMethodName(checkout.method)}'),
      ),
      body: PageBody(
        children: [
          AppCard(
            borderColor: ThemeService.yellow.withValues(alpha: 0.6),
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: ThemeService.yellow),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text('Chế độ demo: giao dịch giả lập, không trừ tiền thật.', style: text.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    PaymentMethodBadge(method: checkout.method, size: 48),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BLUSH Gaming', style: text.titleMedium),
                          Text('Mã đơn #${checkout.orderCode}', style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpace.xl),
                Text('Số tiền thanh toán', style: text.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: AppSpace.xs),
                Text(formatVnd(checkout.amount), textAlign: TextAlign.center, style: text.headlineSmall?.copyWith(color: brand.color, fontSize: 30)),
                const SizedBox(height: AppSpace.xs),
                PaymentCountdown(expiresAt: checkout.expiresAt, style: text.bodySmall?.copyWith(color: ThemeService.yellow)),
                const SizedBox(height: AppSpace.lg),
                _InfoRow(label: 'Gói', value: checkout.packageName),
                _InfoRow(label: 'Tài khoản', value: '${paymentMethodName(checkout.method)} của bạn'),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: brand.color),
            onPressed: _busy ? null : () => _complete(true),
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.verified_outlined),
            label: Text('Xác nhận thanh toán ${formatVnd(checkout.amount)}'),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(onPressed: _busy ? null : _cancel, child: const Text('Hủy giao dịch')),
          const SizedBox(height: AppSpace.sm),
          TextButton(onPressed: _busy ? null : () => _complete(false), child: const Text('Giả lập giao dịch thất bại')),
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

// ── Chờ xác nhận khi trả tiền trên trang/app MoMo (Sandbox/Production) ──
class PaymentWaitingScreen extends StatefulWidget {
  final CheckoutResult checkout;

  const PaymentWaitingScreen({super.key, required this.checkout});

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> with WidgetsBindingObserver, TransactionPolling<PaymentWaitingScreen> {
  @override
  late final PaymentService paymentService = PaymentService(context.read<AuthService>());

  @override
  int get pollingOrderCode => widget.checkout.orderCode;

  @override
  void initState() {
    super.initState();
    startPolling();
  }

  @override
  void onTransactionFinished(PaymentTransaction transaction) => _showResult(context, transaction);

  Future<void> _reopen() async {
    final url = Uri.tryParse(widget.checkout.paymentUrl ?? '');
    if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
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
    final text = Theme.of(context).textTheme;
    final checkout = widget.checkout;
    return Scaffold(
      appBar: AppBar(title: Text(paymentMethodName(checkout.method))),
      body: PageBody(
        children: [
          const SizedBox(height: AppSpace.xl),
          Center(child: PaymentMethodBadge(method: checkout.method, size: 72)),
          const SizedBox(height: AppSpace.xl),
          Text('Hoàn tất thanh toán trên trang ${paymentMethodName(checkout.method)}', textAlign: TextAlign.center, style: text.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Trả xong hãy quay lại app, BLUSH sẽ tự kích hoạt gói ${checkout.packageName}.',
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppSpace.xl),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppSpace.md),
          Center(child: PaymentCountdown(expiresAt: checkout.expiresAt, style: text.bodySmall)),
          const SizedBox(height: AppSpace.xl),
          ElevatedButton.icon(onPressed: _reopen, icon: const Icon(Icons.open_in_new), label: const Text('Mở lại trang thanh toán')),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(onPressed: _cancel, child: const Text('Hủy giao dịch')),
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
