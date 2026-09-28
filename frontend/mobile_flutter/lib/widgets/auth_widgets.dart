import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';

/// Ô nhập chữ dùng chung cho các màn xác thực (OTP, quên mật khẩu)
class AuthTextField extends StatelessWidget {
  final ThemeService theme;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.theme,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: _decoration(theme, hint: hint, icon: icon),
    );
  }
}

/// Ô nhập mã OTP 6 số (chỉ cho gõ số, chữ to cách xa nhau)
class OtpCodeField extends StatelessWidget {
  final ThemeService theme;
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;

  const OtpCodeField({super.key, required this.theme, required this.controller, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: theme.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12),
      decoration: _decoration(theme, hint: '••••••').copyWith(counterText: ''),
      onChanged: (value) {
        if (value.length == 6) onCompleted?.call(value);
      },
    );
  }
}

/// Nút "Gửi lại mã" có đếm ngược 60 giây (giống giới hạn của backend).
/// [onResend] ném lỗi nếu gửi thất bại (khi đó không đếm ngược lại).
class ResendCodeButton extends StatefulWidget {
  final Future<void> Function() onResend;

  const ResendCodeButton({super.key, required this.onResend});

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  static const _cooldown = 60;
  int _secondsLeft = _cooldown; // vừa vào màn hình là mã mới được gửi -> đếm ngược luôn
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await widget.onResend();
      _startCountdown();
    } catch (_) {
      // onResend đã tự báo lỗi cho người dùng; không đếm ngược lại để họ bấm thử lần nữa
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 0 && !_sending;
    return TextButton(
      onPressed: canResend ? _resend : null,
      child: Text(
        _secondsLeft > 0 ? 'Gửi lại mã sau ${_secondsLeft}s' : 'Gửi lại mã',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Nút chính (tím) có trạng thái đang tải
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const AuthPrimaryButton({super.key, required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeService.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
    );
  }
}

/// Khung màn hình "nhập mã 6 số đã gửi tới email" dùng chung cho:
/// xác minh email khi đăng ký, và đăng nhập 2 bước.
class OtpEntryPage extends StatelessWidget {
  final ThemeService theme;
  final String appBarTitle;
  final IconData icon;
  final String heading;
  final String email;
  final TextEditingController controller;
  final String submitLabel;
  final bool loading;
  final VoidCallback onSubmit;
  final Future<void> Function() onResend;
  final Widget? extra; // chèn thêm giữa ô nhập mã và nút (VD: ô "Tin cậy thiết bị này")

  const OtpEntryPage({
    super.key,
    required this.theme,
    required this.appBarTitle,
    required this.icon,
    required this.heading,
    required this.email,
    required this.controller,
    required this.submitLabel,
    required this.loading,
    required this.onSubmit,
    required this.onResend,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(title: Text(appBarTitle), backgroundColor: theme.header, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 64, color: ThemeService.accentLight),
                  const SizedBox(height: 16),
                  Text(heading, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(color: theme.textMuted, height: 1.5),
                      children: [
                        const TextSpan(text: 'Mã 6 số đã được gửi tới\n'),
                        TextSpan(text: email, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                        const TextSpan(text: '\nKiểm tra cả thư mục Spam nếu không thấy.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OtpCodeField(theme: theme, controller: controller, onCompleted: (_) => onSubmit()),
                  if (extra != null) ...[const SizedBox(height: 12), extra!],
                  const SizedBox(height: 20),
                  AuthPrimaryButton(label: submitLabel, loading: loading, onPressed: onSubmit),
                  const SizedBox(height: 8),
                  ResendCodeButton(onResend: onResend),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: ThemeService.red));
}

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: ThemeService.accent));
}

InputDecoration _decoration(ThemeService theme, {required String hint, IconData? icon}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: width));
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: theme.textMuted.withValues(alpha: 0.7)),
    prefixIcon: icon == null ? null : Icon(icon, color: theme.textMuted, size: 20),
    filled: true,
    fillColor: theme.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(theme.border),
    enabledBorder: border(theme.border),
    focusedBorder: border(ThemeService.accent, 1.5),
  );
}
