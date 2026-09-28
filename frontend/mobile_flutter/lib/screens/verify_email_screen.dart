import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/auth_widgets.dart';

/// Nhập mã 6 số gửi về email để xác minh tài khoản. Đúng mã -> đăng nhập luôn.
class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6) {
      showErrorSnack(context, 'Vui lòng nhập đủ 6 chữ số.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().verifyEmail(widget.email, _codeCtrl.text);
      // Đã đăng nhập -> quay về màn đầu, main.dart tự chuyển sang trang chủ
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthService>().resendOtp(widget.email, 'VerifyEmail');
      if (mounted) showSuccessSnack(context, 'Đã gửi mã mới tới ${widget.email}');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
      rethrow; // để nút không bắt đầu đếm ngược lại
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(title: const Text('Xác minh email'), backgroundColor: theme.header, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 64, color: ThemeService.accentLight),
                  const SizedBox(height: 16),
                  Text('Nhập mã xác minh', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(color: theme.textMuted, height: 1.5),
                      children: [
                        const TextSpan(text: 'Mã 6 số đã được gửi tới\n'),
                        TextSpan(text: widget.email, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                        const TextSpan(text: '\nKiểm tra cả thư mục Spam nếu không thấy.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OtpCodeField(theme: theme, controller: _codeCtrl, onCompleted: (_) => _verify()),
                  const SizedBox(height: 20),
                  AuthPrimaryButton(label: 'XÁC MINH & VÀO APP', loading: _loading, onPressed: _verify),
                  const SizedBox(height: 8),
                  ResendCodeButton(onResend: _resend),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
