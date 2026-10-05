import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Màu nhận diện + chữ viết tắt của từng phương thức thanh toán
class PaymentBrand {
  final Color color;
  final String shortName;

  const PaymentBrand(this.color, this.shortName);

  static PaymentBrand of(String method) => switch (method) {
        'MoMo' => const PaymentBrand(Color(0xFFA50064), 'MoMo'),
        // Không còn nhận thanh toán mới, giữ để hiện giao dịch cũ trong lịch sử
        'VNPay' => const PaymentBrand(Color(0xFF005BAA), 'VNPAY'),
        'ZaloPay' => const PaymentBrand(Color(0xFF0068FF), 'Zalo\nPay'),
        'VietQR' => const PaymentBrand(Color(0xFF0E9F6E), 'Viet\nQR'),
        _ => const PaymentBrand(ThemeService.accent, '₫'),
      };
}

/// Ô vuông màu thương hiệu (thay logo thật)
class PaymentMethodBadge extends StatelessWidget {
  final String method;
  final double size;

  const PaymentMethodBadge({super.key, required this.method, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final brand = PaymentBrand.of(method);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: brand.color, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        brand.shortName,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: size * 0.24, fontWeight: FontWeight.w800, height: 1.05),
      ),
    );
  }
}

/// Nhãn trạng thái giao dịch có màu
class TransactionStatusChip extends StatelessWidget {
  final String status; // 'Pending' | 'Paid' | 'Failed' | 'Cancelled'

  const TransactionStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    // Nền sáng: dùng tông đậm hơn để chữ đủ tương phản
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (status) {
      PaymentTransaction.paid => isDark ? ThemeService.green : const Color(0xFF15803D),
      PaymentTransaction.pending => isDark ? ThemeService.yellow : const Color(0xFFB45309),
      PaymentTransaction.failed => ThemeService.red,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(transactionStatusLabel(status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Đồng hồ "Hết hạn sau 14:59"
class PaymentCountdown extends StatefulWidget {
  final DateTime? expiresAt;
  final TextStyle? style;

  const PaymentCountdown({super.key, required this.expiresAt, this.style});

  @override
  State<PaymentCountdown> createState() => _PaymentCountdownState();
}

class _PaymentCountdownState extends State<PaymentCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = widget.expiresAt;
    if (expiresAt == null) return const SizedBox.shrink();
    final left = expiresAt.difference(DateTime.now());
    if (left.isNegative) return Text('Giao dịch đã hết hạn', style: widget.style);
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Text('Hết hạn sau $mm:$ss', style: widget.style);
  }
}

/// Hỏi backend trạng thái giao dịch vài giây 1 lần trong lúc người dùng trả tiền
/// (chuyển khoản VietQR, hoặc trả trên trang/app MoMo ngoài app BLUSH).
/// Có kết quả (khác Pending) thì gọi [onTransactionFinished].
mixin TransactionPolling<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  static const pollInterval = Duration(seconds: 3);

  Timer? _pollTimer;
  bool _finished = false;
  bool _checking = false;

  PaymentService get paymentService;
  int get pollingOrderCode;
  void onTransactionFinished(PaymentTransaction transaction);

  void startPolling() {
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(pollInterval, (_) => checkNow());
  }

  /// Hỏi ngay (VD: vừa từ trình duyệt quay lại app)
  Future<void> checkNow() async {
    if (_finished || _checking) return;
    _checking = true;
    try {
      final transaction = await paymentService.getTransaction(pollingOrderCode);
      if (!transaction.isPending && mounted && !_finished) {
        _finished = true;
        _pollTimer?.cancel();
        onTransactionFinished(transaction);
      }
    } on ApiException {
      // Mất mạng tạm thời: lần sau hỏi lại
    } finally {
      _checking = false;
    }
  }

  /// Dừng hỏi (khi người dùng tự hủy / tự xác nhận)
  void stopPolling() {
    _finished = true;
    _pollTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkNow();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
