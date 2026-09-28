import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/auth_widgets.dart';

/// Quên mật khẩu: bước 1 nhập email -> bước 2 nhập mã OTP + mật khẩu mới.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _codeSent = false; // false = bước 1, true = bước 2
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthService auth) action) async {
    setState(() => _loading = true);
    try {
      await action(context.read<AuthService>());
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sendCode() {
    if (!_emailCtrl.text.contains('@')) {
      showErrorSnack(context, 'Email không hợp lệ.');
      return;
    }
    _run((auth) async {
      final message = await auth.forgotPassword(_emailCtrl.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      showSuccessSnack(context, message);
    });
  }

  Future<void> _resendCode() async {
    try {
      await context.read<AuthService>().resendOtp(_emailCtrl.text, 'ResetPassword');
      if (mounted) showSuccessSnack(context, 'Đã gửi mã mới.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
      rethrow; // để nút không đếm ngược lại
    }
  }

  void _resetPassword() {
    final String? error = _codeCtrl.text.length != 6
        ? 'Vui lòng nhập đủ 6 chữ số.'
        : _passCtrl.text.length < 6
            ? 'Mật khẩu phải có ít nhất 6 ký tự.'
            : _passCtrl.text != _confirmCtrl.text
                ? 'Mật khẩu xác nhận không khớp.'
                : null;
    if (error != null) {
      showErrorSnack(context, error);
      return;
    }
    _run((auth) async {
      final message = await auth.resetPassword(email: _emailCtrl.text, code: _codeCtrl.text, newPassword: _passCtrl.text);
      if (!mounted) return;
      showSuccessSnack(context, message);
      Navigator.pop(context, _emailCtrl.text.trim()); // quay về màn đăng nhập, điền sẵn email
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(title: const Text('Quên mật khẩu'), backgroundColor: theme.header, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset, size: 64, color: ThemeService.accentLight),
                  const SizedBox(height: 16),
                  Text(
                    _codeSent ? 'Tạo mật khẩu mới' : 'Đặt lại mật khẩu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent ? 'Nhập mã 6 số đã gửi tới ${_emailCtrl.text.trim()} và mật khẩu mới.' : 'Nhập email đã đăng ký, BLUSH sẽ gửi mã xác minh cho bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (!_codeSent) ...[
                    AuthTextField(theme: theme, controller: _emailCtrl, hint: 'Email của bạn', icon: Icons.alternate_email, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    AuthPrimaryButton(label: 'GỬI MÃ XÁC MINH', loading: _loading, onPressed: _sendCode),
                  ] else ...[
                    OtpCodeField(theme: theme, controller: _codeCtrl),
                    const SizedBox(height: 16),
                    AuthTextField(theme: theme, controller: _passCtrl, hint: 'Mật khẩu mới (tối thiểu 6 ký tự)', icon: Icons.lock, obscure: true),
                    const SizedBox(height: 12),
                    AuthTextField(theme: theme, controller: _confirmCtrl, hint: 'Nhập lại mật khẩu mới', icon: Icons.verified_user, obscure: true),
                    const SizedBox(height: 20),
                    AuthPrimaryButton(label: 'ĐỔI MẬT KHẨU', loading: _loading, onPressed: _resetPassword),
                    const SizedBox(height: 8),
                    ResendCodeButton(onResend: _resendCode),
                    TextButton(
                      onPressed: () => setState(() => _codeSent = false),
                      child: Text('Đổi email khác', style: TextStyle(color: theme.textMuted)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
