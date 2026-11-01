import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../config/app_config.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/google_auth.dart';
import '../theme/app_theme.dart';
import 'forgot_password_screen.dart';
import 'two_factor_screen.dart';
import 'verify_email_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, this.isLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // ── State ──
  late bool _isLoginMode;
  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureConfirm = true;
  bool _agreedTerms = false; // người dùng phải tự tick, không tick sẵn
  int _strengthLevel = 0; // 0=none 1=weak 2=medium 3=strong
  bool _isLoading = false; // đang gọi API -> khóa nút để không bấm 2 lần
  DateTime? _regDob; // ngày sinh (bắt buộc, từ AppConfig.minimumAge tuổi)

  // ── Controllers ──
  // kDebugMode: chỉ điền sẵn tài khoản demo khi đang dev, bản phát hành để trống
  final _loginEmailCtrl = TextEditingController(text: kDebugMode ? 'gamer@blush.vn' : '');
  final _loginPassCtrl = TextEditingController(text: kDebugMode ? '123456' : '');
  final _regTagCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.isLogin;
  }

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regTagCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String val) {
    setState(() {
      if (val.isEmpty) {
        _strengthLevel = 0;
      } else if (val.length < 6) {
        _strengthLevel = 1;
      } else if (val.length < 10) {
        _strengthLevel = 2;
      } else {
        _strengthLevel = 3;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: ThemeService.red),
    );
  }

  /// Chạy 1 thao tác đăng nhập: hiện loading, báo lỗi nếu có, thành công thì quay về màn đầu
  /// (main.dart thấy đã đăng nhập sẽ tự chuyển sang trang chủ).
  Future<void> _runAuth(Future<bool> Function(AuthService auth) action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final success = await action(context.read<AuthService>());
      if (success && mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on ApiException catch (e) {
      if (e.isEmailNotVerified) {
        // Đúng mật khẩu nhưng chưa xác minh email -> backend đã gửi mã, chuyển sang màn nhập mã
        _showError(e.message);
        _openVerifyEmail(_loginEmailCtrl.text.trim());
      } else if (e.isTwoFactorRequired) {
        // Đã bật xác thực 2 bước -> backend đã gửi mã đăng nhập về email
        _openTwoFactor(_loginEmailCtrl.text.trim());
      } else {
        _showError(e.message);
      }
    } on GoogleAuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Đăng nhập thất bại: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _doLogin() {
    if (_loginEmailCtrl.text.trim().isEmpty || _loginPassCtrl.text.isEmpty) {
      _showError('Vui lòng nhập email và mật khẩu.');
      return;
    }
    _runAuth((auth) async {
      await auth.login(_loginEmailCtrl.text, _loginPassCtrl.text);
      return true;
    });
  }

  void _doGoogleLogin() => _runAuth((auth) => auth.loginWithGoogle());

  void _openVerifyEmail(String email) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)));
  }

  void _openTwoFactor(String email) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => TwoFactorScreen(email: email)));
  }

  Future<void> _openForgotPassword() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _loginEmailCtrl.text.trim())),
    );
    // Đổi mật khẩu xong -> điền sẵn email, xóa mật khẩu cũ để người dùng gõ mật khẩu mới
    if (email != null && mounted) {
      setState(() {
        _isLoginMode = true;
        _loginEmailCtrl.text = email;
        _loginPassCtrl.clear();
      });
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _regDob ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) setState(() => _regDob = picked);
  }

  /// Trả về câu báo lỗi, hoặc null nếu form hợp lệ.
  String? _validateRegister() {
    if (_regTagCtrl.text.trim().isEmpty) return 'Vui lòng nhập Gamer Tag.';
    if (_regTagCtrl.text.trim().length > 50) return 'Gamer Tag tối đa 50 ký tự.';
    if (!_regEmailCtrl.text.contains('@')) return 'Email không hợp lệ.';
    if (_regDob == null) return 'Vui lòng chọn ngày sinh.';
    if (!AppConfig.isOldEnough(_regDob!)) return 'BLUSH dành cho người từ ${AppConfig.minimumAge} tuổi trở lên.';
    if (_regPassCtrl.text.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    if (_regPassCtrl.text != _regConfirmCtrl.text) return 'Mật khẩu xác nhận không khớp.';
    if (!_agreedTerms) return 'Bạn cần đồng ý với điều khoản dịch vụ.';
    return null;
  }

  void _doRegister() {
    final error = _validateRegister();
    if (error != null) {
      _showError(error);
      return;
    }
    _runAuth((auth) async {
      final email = _regEmailCtrl.text.trim();
      await auth.register(
        displayName: _regTagCtrl.text,
        email: email,
        password: _regPassCtrl.text,
        dateOfBirth: _regDob!,
      );
      // Chưa đăng nhập: chuyển sang màn nhập mã OTP vừa gửi về email
      if (mounted) _openVerifyEmail(email);
      return false;
    });
  }

  static const double _heroHeight = 320;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          // Ảnh game phía trên, tối dần rồi hòa vào nền -> chữ trắng luôn đọc được ở cả 2 theme
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Đẩy ảnh lên để cắt dòng chữ in sẵn ở mép trên ảnh (giống màn chào)
                Positioned(
                  top: -90,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/hero_banner.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: ThemeService.accentContainer),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.35), Colors.black.withValues(alpha: 0.6), t.bg],
                      stops: const [0, 0.6, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: canPop
                              ? IconButton(
                                  tooltip: 'Quay lại',
                                  onPressed: () => Navigator.maybePop(context),
                                  style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.3)),
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 64,
                          errorBuilder: (_, __, ___) => Text('BLUSH', style: text.headlineSmall?.copyWith(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        _isLoginMode ? 'Chào mừng trở lại 👋' : 'Tham gia BLUSH',
                        style: text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        _isLoginMode ? 'Đăng nhập để tìm đồng đội hợp gu' : 'Tạo tài khoản miễn phí, ghép đội trong 1 phút',
                        style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpace.xl),
                      _buildSheet(t, text),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tấm form bo góc: form email, rồi nút Google, cuối cùng là link chuyển Đăng nhập / Đăng ký
  Widget _buildSheet(ThemeService t, TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: t.isDark ? 0.4 : 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      // Material trong suốt: ô "Tôi đồng ý" (ListTile) vẽ hiệu ứng chạm lên đây thay vì bị nền tấm form che
      child: Material(
        type: MaterialType.transparency,
        child: _sheetContent(t, text),
      ),
    );
  }

  Widget _sheetContent(ThemeService t, TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chọn nhanh tài khoản demo: CHỈ hiện khi đang dev, bản phát hành ẩn đi
        if (kDebugMode && _isLoginMode) ...[
          _buildDemoAccounts(text),
          const SizedBox(height: AppSpace.lg),
        ],

        if (_isLoginMode) ..._buildLoginForm(text) else ..._buildRegisterForm(text),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              child: Text('hoặc', style: text.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        // Nút Google nền trắng theo chuẩn thiết kế của Google
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: Color(0xFFDADCE0)),
          ),
          onPressed: _isLoading ? null : _doGoogleLogin,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('G', style: TextStyle(color: Color(0xFFEA4335), fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(width: AppSpace.md),
              Flexible(child: Text('Tiếp tục với Google', overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // Chuyển Đăng nhập / Đăng ký
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(_isLoginMode ? 'Chưa có tài khoản?' : 'Đã có tài khoản?', style: text.bodyMedium?.copyWith(color: t.textMuted)),
            TextButton(
              onPressed: _isLoading ? null : () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode ? 'Đăng ký ngay' : 'Đăng nhập', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoAccounts(TextTheme text) {
    const accounts = {'Gamer': 'gamer@blush.vn', 'Staff': 'staff@blush.vn', 'Admin': 'admin@blush.vn'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tài khoản demo (chỉ hiện khi dev)', style: text.labelMedium),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            for (final e in accounts.entries)
              ChoiceChip(
                label: Text(e.key),
                selected: _loginEmailCtrl.text == e.value,
                onSelected: (_) => setState(() {
                  _loginEmailCtrl.text = e.value;
                  _loginPassCtrl.text = '123456';
                }),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildLoginForm(TextTheme text) {
    return [
      TextField(
        controller: _loginEmailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
      ),
      const SizedBox(height: AppSpace.md),
      _passwordField(controller: _loginPassCtrl, label: 'Mật khẩu', obscure: _obscureLogin, onToggle: () => setState(() => _obscureLogin = !_obscureLogin)),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _openForgotPassword, child: const Text('Quên mật khẩu?'))),
      const SizedBox(height: AppSpace.sm),
      _submitButton('Đăng nhập', _doLogin),
    ];
  }

  List<Widget> _buildRegisterForm(TextTheme text) {
    final dob = _regDob;
    return [
      TextField(
        controller: _regTagCtrl,
        decoration: const InputDecoration(labelText: 'Tên hiển thị (Gamer Tag)', hintText: 'VD: ShadowNinja', prefixIcon: Icon(Icons.badge_outlined)),
      ),
      const SizedBox(height: AppSpace.md),
      TextField(
        controller: _regEmailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
      ),
      const SizedBox(height: AppSpace.md),
      // Ô ngày sinh: bấm vào mở lịch, không cho gõ tay để tránh sai định dạng
      InkWell(
        onTap: _pickDob,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Ngày sinh (từ ${AppConfig.minimumAge} tuổi)',
            prefixIcon: Icon(Icons.cake_outlined),
            suffixIcon: Icon(Icons.calendar_month),
          ),
          child: Text(
            dob == null ? 'Chọn ngày sinh' : '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}',
            style: dob == null ? text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant) : text.bodyMedium,
          ),
        ),
      ),
      const SizedBox(height: AppSpace.md),
      _passwordField(
        controller: _regPassCtrl,
        label: 'Mật khẩu (tối thiểu 6 ký tự)',
        obscure: _obscureReg,
        onToggle: () => setState(() => _obscureReg = !_obscureReg),
        onChanged: _checkStrength,
      ),
      const SizedBox(height: AppSpace.sm),
      _strengthIndicator(text),
      const SizedBox(height: AppSpace.md),
      _passwordField(
          controller: _regConfirmCtrl,
          label: 'Nhập lại mật khẩu',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
      const SizedBox(height: AppSpace.sm),
      CheckboxListTile(
        value: _agreedTerms,
        onChanged: (v) => setState(() => _agreedTerms = v ?? false),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text('Tôi đồng ý với Điều khoản và Quy tắc ứng xử của BLUSH', style: text.bodyMedium),
      ),
      const SizedBox(height: AppSpace.sm),
      _submitButton('Tạo tài khoản', _doRegister),
    ];
  }

  Widget _strengthIndicator(TextTheme text) {
    const labels = ['', 'Yếu', 'Trung bình', 'Mạnh'];
    const colors = [Colors.transparent, ThemeService.red, Colors.orange, ThemeService.green];
    final muted = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: _strengthLevel >= i ? colors[_strengthLevel] : muted, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
        SizedBox(width: 72, child: Text(labels[_strengthLevel], style: text.labelSmall, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _submitButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      onPressed: _isLoading ? null : onPressed,
      child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
    );
  }
}
