import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/auth_widgets.dart';

/// Bước 2 khi đăng nhập tài khoản đã bật xác thực 2 bước: nhập mã gửi về email.
class TwoFactorScreen extends StatefulWidget {
  final String email;

  const TwoFactorScreen({super.key, required this.email});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeCtrl = TextEditingController();
  bool _rememberDevice = true;
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
      await context.read<AuthService>().loginWithTwoFactor(widget.email, _codeCtrl.text, rememberDevice: _rememberDevice);
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
      await context.read<AuthService>().resendOtp(widget.email, 'TwoFactorLogin');
      if (mounted) showSuccessSnack(context, 'Đã gửi mã mới tới ${widget.email}');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
      rethrow; // để nút không bắt đầu đếm ngược lại
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return OtpEntryPage(
      theme: theme,
      appBarTitle: 'Xác thực 2 bước',
      icon: Icons.verified_user_outlined,
      heading: 'Nhập mã đăng nhập',
      email: widget.email,
      controller: _codeCtrl,
      submitLabel: 'XÁC NHẬN & ĐĂNG NHẬP',
      loading: _loading,
      onSubmit: _verify,
      onResend: _resend,
      extra: CheckboxListTile(
        value: _rememberDevice,
        onChanged: (v) => setState(() => _rememberDevice = v ?? false),
        activeColor: ThemeService.accent,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text('Tin cậy thiết bị này 30 ngày', style: TextStyle(color: theme.textPrimary, fontSize: 14)),
        subtitle: Text('Không hỏi mã khi đăng nhập lại trên máy này', style: TextStyle(color: theme.textMuted, fontSize: 12)),
      ),
    );
  }
}
