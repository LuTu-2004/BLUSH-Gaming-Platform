import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Thanh toán gói VIP bằng VietQR (bản demo: bấm xác nhận là kích hoạt).
class CheckoutScreen extends StatefulWidget {
  final String planName;
  final String price;

  const CheckoutScreen({super.key, required this.planName, required this.price});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: PageBody(
        children: [
          if (_isPaid) ...[
            const SizedBox(height: AppSpace.xxl),
            const Icon(Icons.check_circle, color: ThemeService.green, size: 72),
            const SizedBox(height: AppSpace.lg),
            Text('Thanh toán thành công', textAlign: TextAlign.center, style: text.headlineSmall),
            const SizedBox(height: AppSpace.sm),
            Text('${widget.planName} đã được kích hoạt cho tài khoản của bạn.', textAlign: TextAlign.center, style: text.bodyMedium),
            const SizedBox(height: AppSpace.xl),
            ElevatedButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Về trang chủ')),
          ] else ...[
            AppCard(
              child: Column(
                children: [
                  Text(widget.planName, style: text.titleMedium),
                  const SizedBox(height: AppSpace.xs),
                  Text(widget.price, style: text.headlineSmall),
                  const SizedBox(height: AppSpace.lg),
                  // QR minh họa (TODO: dùng qrImageUrl trả về từ POST api/payment/create-checkout)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)),
                    child: const Icon(Icons.qr_code_2, size: 160, color: Colors.black),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const _InfoRow(label: 'Ngân hàng', value: 'MB Bank'),
                  const _InfoRow(label: 'Số tài khoản', value: '0388888888'),
                  const _InfoRow(label: 'Chủ tài khoản', value: 'BLUSH GAMING'),
                  _InfoRow(label: 'Nội dung', value: 'BLUSH ${widget.planName.replaceAll(' ', '')}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text('Mở app ngân hàng, quét mã QR và giữ nguyên nội dung chuyển khoản.', textAlign: TextAlign.center, style: text.bodySmall),
            const SizedBox(height: AppSpace.xl),
            ElevatedButton(
              onPressed: () {
                // TODO: khi có backend, gọi POST api/payment/create-checkout và chờ PayOS xác nhận
                context.read<AuthService>().activateVip();
                setState(() => _isPaid = true);
              },
              child: const Text('Tôi đã chuyển khoản'),
            ),
            const SizedBox(height: AppSpace.sm),
            Text('Bản demo: bấm nút trên là kích hoạt ngay.', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: t.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Text(label, style: text.bodySmall),
          const Spacer(),
          Text(value, style: text.titleSmall),
        ],
      ),
    );
  }
}
