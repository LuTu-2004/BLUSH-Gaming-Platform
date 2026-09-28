import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/auth_widgets.dart';

/// Bật 2 bước - bước 2: nhập mã vừa gửi về email để chứng minh nhận được mã.
/// Trả về true (Navigator.pop) nếu bật thành công.
class EnableTwoFactorScreen extends StatefulWidget {
  final String email;
  final String password; // giữ tạm trong bộ nhớ để "Gửi lại mã" (backend yêu cầu mật khẩu)

  const EnableTwoFactorScreen({super.key, required this.email, required this.password});

  @override
  State<EnableTwoFactorScreen> createState() => _EnableTwoFactorScreenState();
}

class _EnableTwoFactorScreenState extends State<EnableTwoFactorScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_codeCtrl.text.length != 6) {
      showErrorSnack(context, 'Vui lòng nhập đủ 6 chữ số.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().confirmEnableTwoFactor(_codeCtrl.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthService>().startEnableTwoFactor(widget.password);
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
      appBarTitle: 'Bật xác thực 2 bước',
      icon: Icons.shield_outlined,
      heading: 'Xác nhận email nhận mã',
      email: widget.email,
      controller: _codeCtrl,
      submitLabel: 'BẬT XÁC THỰC 2 BƯỚC',
      loading: _loading,
      onSubmit: _confirm,
      onResend: _resend,
    );
  }
}
