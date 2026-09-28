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
    return OtpEntryPage(
      theme: context.watch<ThemeService>(),
      appBarTitle: 'Xác minh email',
      icon: Icons.mark_email_unread_outlined,
      heading: 'Nhập mã xác minh',
      email: widget.email,
      controller: _codeCtrl,
      submitLabel: 'XÁC MINH & VÀO APP',
      loading: _loading,
      onSubmit: _verify,
      onResend: _resend,
    );
  }
}
