import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String planName;
  final String price;

  const CheckoutScreen({
    super.key,
    required this.planName,
    required this.price,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: Text('Thanh Toán ${widget.planName}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.header,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ThemeService.blurple.withValues(alpha: 0.4)),
              ),
              child: _isPaid
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: ThemeService.green, size: 72),
                        const SizedBox(height: 16),
                        Text('THANH TOÁN THÀNH CÔNG! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Gói ${widget.planName} đã được kích hoạt cho tài khoản của bạn.', textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeService.blurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('TRỞ VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: ThemeService.blurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('CỔNG THANH TOÁN VIETQR / PAYOS', style: TextStyle(color: ThemeService.blurple, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(height: 16),
                        Text('Tổng thanh toán: ${widget.price}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Nội dung CK: BLUSH ${widget.planName.replaceAll(" ", "")}', style: const TextStyle(color: ThemeService.yellow, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Fake QR Code box
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ThemeService.blurple, width: 3),
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2, size: 140, color: Colors.black),
                                  Text('Quét mã VietQR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Ngân hàng: MB Bank • STK: 0388888888 • Tên: BLUSH GAMING', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeService.green,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              // TODO: khi có backend, gọi POST api/payment/create-checkout và chờ PayOS xác nhận
                              context.read<AuthService>().activateVip();
                              setState(() {
                                _isPaid = true;
                              });
                            },
                            child: const Text('XÁC NHẬN ĐÃ CHUYỂN KHOẢN ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
