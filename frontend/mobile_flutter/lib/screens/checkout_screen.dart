import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'payment_flow_screens.dart';

/// Thanh toán 1 gói VIP: chọn phương thức -> bấm "Thanh toán" -> POST api/payment/checkout, rồi:
///   - VietQR: màn quét QR chuyển khoản
///   - Chế độ giả lập (backend Payment:Mode = Mock): màn cổng thanh toán giả lập trong app
///   - Chạy thật (Sandbox): mở trang MoMo/VNPay/ZaloPay trên trình duyệt + màn chờ xác nhận
class CheckoutScreen extends StatefulWidget {
  final VipPackage package;

  const CheckoutScreen({super.key, required this.package});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final PaymentService _service = PaymentService(context.read<AuthService>());
  List<PaymentMethodOption>? _methods;
  String? _selected;
  String? _loadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() => _loadError = null);
    try {
      final methods = await _service.getMethods();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _selected = methods.where((m) => m.isAvailable).firstOrNull?.code;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _pay() async {
    final method = _selected;
    if (method == null) return;
    setState(() => _submitting = true);
    try {
      final checkout = await _service.checkout(packageCode: widget.package.code, method: method);
      if (!mounted) return;

      final Widget next;
      if (checkout.method == 'VietQR') {
        next = BankTransferScreen(checkout: checkout);
      } else if (checkout.isMock) {
        next = MockGatewayScreen(checkout: checkout);
      } else {
        final url = Uri.tryParse(checkout.paymentUrl ?? '');
        if (url == null || !await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (mounted) showErrorSnack(context, 'Không mở được trang thanh toán. Thử phương thức khác nhé.');
          return;
        }
        next = PaymentWaitingScreen(checkout: checkout);
      }
      if (mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => next));
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final package = widget.package;
    final methods = _methods;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Column(
        children: [
          Expanded(
            child: PageBody(
              children: [
                // ── Đơn hàng ─────────────────────────────────────
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: ThemeService.yellow, size: 36),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(package.name, style: text.titleMedium),
                            Text('Thời hạn ${package.durationDays} ngày', style: text.bodySmall),
                          ],
                        ),
                      ),
                      Text(formatVnd(package.price), style: text.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // ── Phương thức ─────────────────────────────────
                const SectionHeader('Phương thức thanh toán'),
                if (_loadError != null)
                  AppCard(
                    onTap: _loadMethods,
                    child: Text('$_loadError Chạm để thử lại.', textAlign: TextAlign.center, style: text.bodySmall),
                  )
                else if (methods == null)
                  const Padding(padding: EdgeInsets.all(AppSpace.lg), child: Center(child: CircularProgressIndicator()))
                else
                  for (final m in methods) ...[
                    _MethodTile(
                      method: m,
                      selected: _selected == m.code,
                      onTap: m.isAvailable && !_submitting ? () => setState(() => _selected = m.code) : null,
                    ),
                    const SizedBox(height: AppSpace.sm),
                  ],
                const SizedBox(height: AppSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: t.textMuted),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        'BLUSH không lưu thông tin thẻ hay ví của bạn. Gói được kích hoạt ngay khi cổng thanh toán xác nhận.',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tổng tiền + nút thanh toán ─────────────────────────
          Container(
            decoration: BoxDecoration(color: t.header, border: Border(top: BorderSide(color: t.border))),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tổng thanh toán', style: text.bodySmall),
                          Text(formatVnd(package.price), style: text.titleLarge),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _selected != null && !_submitting ? _pay : null,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Thanh toán'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodTile({required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return Opacity(
      opacity: method.isAvailable ? 1 : 0.5,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? ThemeService.accent : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: Row(
          children: [
            PaymentMethodBadge(method: method.code),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name, style: text.titleSmall),
                  Text(method.isAvailable ? method.description : 'Chưa hỗ trợ', style: text.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? ThemeService.accent : t.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
