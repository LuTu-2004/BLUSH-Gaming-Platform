import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, this.isLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // ── State ──
  late bool _isLoginMode;
  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureConfirm = true;
  bool _rememberMe = true;
  bool _agreedTerms = true;
  int _strengthLevel = 0; // 0=none 1=weak 2=medium 3=strong

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ── Controllers ──
  final _loginEmailCtrl = TextEditingController(text: 'gamer@blush.vn');
  final _loginPassCtrl = TextEditingController(text: '123456');
  final _regTagCtrl = TextEditingController(text: 'ShadowNinja#VN1');
  final _regEmailCtrl = TextEditingController(text: 'ma_sinh_vien@daihoc.edu.vn');
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.isLogin;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regTagCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String val) {
    if (val.isEmpty) setState(() => _strengthLevel = 0);
    else if (val.length < 6) setState(() => _strengthLevel = 1);
    else if (val.length < 10) setState(() => _strengthLevel = 2);
    else setState(() => _strengthLevel = 3);
  }

  void _doLogin() {
    context.read<AuthService>().loginDemo(_loginEmailCtrl.text);
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  void _doRegister() {
    context.read<AuthService>().loginDemo(_regEmailCtrl.text);
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      body: Column(
        children: [
          // ── HEADER (fixed top) ─────────────────────────────────────────
          _buildHeader(theme),

          // ── SCROLLABLE BODY ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      _buildBrandSection(theme),
                      const SizedBox(height: 20),
                      _buildTabSwitcher(theme),
                      const SizedBox(height: 20),
                      // Demo role quick-select
                      _buildDemoRoles(theme),
                      const SizedBox(height: 16),
                      // Form (animated switch)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isLoginMode
                            ? _buildLoginForm(theme, key: const ValueKey('login'))
                            : _buildRegisterForm(theme, key: const ValueKey('register')),
                      ),
                      const SizedBox(height: 20),
                      _buildSocialSection(theme),
                      const SizedBox(height: 20),
                      _buildPostLoginInfo(theme),
                      const SizedBox(height: 20),
                      _buildTrustSection(theme),
                      const SizedBox(height: 32),
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

  // ════════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════════
  Widget _buildHeader(ThemeService theme) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.header,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: back + logo
          Row(
            children: [
              IconButton(
                tooltip: 'Quay lại',
                icon: Icon(Icons.arrow_back_ios_new, color: theme.textPrimary, size: 20),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              Image.asset(
                'assets/images/logo.png',
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'BLUSH',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5,
                        color: theme.isDark ? ThemeService.accentLight : ThemeService.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Right: Theme Toggle + Mode title + Help button
          Row(
            children: [
              IconButton(
                tooltip: theme.isDark ? 'Chuyển Chế Độ Sáng' : 'Chuyển Chế Độ Tối',
                icon: Icon(
                  theme.isDark ? Icons.light_mode : Icons.dark_mode,
                  color: theme.isDark ? Colors.amber : ThemeService.accent,
                ),
                onPressed: () {
                  context.read<ThemeService>().toggleTheme();
                },
              ),
              Text(
                _isLoginMode ? 'Đăng Nhập' : 'Đăng Ký',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textMuted),
              ),
              IconButton(
                tooltip: 'Hỗ trợ & Trợ giúp',
                icon: Icon(Icons.help_outline, color: theme.textMuted, size: 20),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Liên hệ hỗ trợ: support@blush.vn')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BRAND SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildBrandSection(ThemeService theme) {
    return Column(
      children: [
        // Logo with glow blob
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ThemeService.accent.withOpacity(_pulseAnim.value * 0.35),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              // Logo box
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ThemeService.accent.withOpacity(0.4), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/mascot.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(child: Text('🎮', style: TextStyle(fontSize: 42))),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Badge — pulsing dot
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: ThemeService.accent.withOpacity(theme.isDark ? 0.25 : 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: ThemeService.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ThemeService.accent,
                    boxShadow: [BoxShadow(color: ThemeService.accent, blurRadius: 6 * _pulseAnim.value)],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'HỆ THỐNG AI GAMING SOCIAL #1 CHO SINH VIÊN',
                  style: TextStyle(
                    color: theme.isDark ? ThemeService.accentLight : ThemeService.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.textPrimary, letterSpacing: -0.3),
            children: [
              const TextSpan(text: 'Sảnh Chờ '),
              TextSpan(
                text: 'BLUSH',
                style: TextStyle(color: theme.isDark ? ThemeService.accentLight : ThemeService.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: theme.textMuted, height: 1.5),
            children: [
              const TextSpan(text: 'Kết nối game thủ bằng '),
              TextSpan(
                text: 'phong cách chơi & tính cách',
                style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: ', không phải ngoại hình.'),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TAB SWITCHER
  // ════════════════════════════════════════════════════════════════
  Widget _buildTabSwitcher(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          _tabChip(theme, 'Đăng Nhập', Icons.login, true),
          _tabChip(theme, 'Đăng Ký', Icons.person_add, false),
        ],
      ),
    );
  }

  Widget _tabChip(ThemeService theme, String label, IconData icon, bool forLogin) {
    final active = _isLoginMode == forLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isLoginMode = forLogin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? ThemeService.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [BoxShadow(color: ThemeService.accent.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : theme.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: active ? Colors.white : theme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // DEMO ROLE QUICK-SELECT
  // ════════════════════════════════════════════════════════════════
  Widget _buildDemoRoles(ThemeService theme) {
    final roles = [
      {'label': 'Gamer', 'email': 'gamer@blush.vn', 'icon': '🎮', 'color': ThemeService.cyan},
      {'label': 'Mentor', 'email': 'staff@blush.vn', 'icon': '🛡️', 'color': ThemeService.accent},
      {'label': 'Admin', 'email': 'admin@blush.vn', 'icon': '⚡', 'color': ThemeService.pink},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 12, color: theme.textMuted),
            const SizedBox(width: 4),
            Text(
              'DEMO NHANH VAI TRÒ:',
              style: TextStyle(color: theme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: roles.map((r) {
            final color = r['color'] as Color;
            final email = r['email'] as String;
            final currentEmail = _isLoginMode ? _loginEmailCtrl.text : _regEmailCtrl.text;
            final selected = currentEmail == email;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isLoginMode) _loginEmailCtrl.text = email;
                    else _regEmailCtrl.text = email;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.18) : theme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : theme.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(r['icon'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 3),
                      Text(
                        r['label'] as String,
                        style: TextStyle(
                          color: selected ? color : theme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LOGIN FORM
  // ════════════════════════════════════════════════════════════════
  Widget _buildLoginForm(ThemeService theme, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        _inputLabel(theme, 'TÀI KHOẢN SINH VIÊN'),
        const SizedBox(height: 6),
        _inputField(
          theme: theme,
          controller: _loginEmailCtrl,
          hint: 'gamethu@sinhvien.edu.vn hoặc tên ID',
          prefixIcon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),

        // Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _inputLabel(theme, 'MẬT KHẨU'),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              onPressed: () {},
              child: Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  color: theme.isDark ? ThemeService.accentLight : ThemeService.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _passwordField(
          theme: theme,
          controller: _loginPassCtrl,
          hint: '••••••••••••',
          obscure: _obscureLogin,
          onToggle: () => setState(() => _obscureLogin = !_obscureLogin),
        ),
        const SizedBox(height: 14),

        // Remember me + status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: ThemeService.accent,
                      side: BorderSide(color: theme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Ghi nhớ phiên đăng nhập', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeService.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ThemeService.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: ThemeService.green)),
                  const SizedBox(width: 5),
                  const Text('Sẵn sàng ghép đội', style: TextStyle(color: ThemeService.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Submit
        _submitBtn(theme, 'ĐĂNG NHẬP NGAY', Icons.sports_esports, _doLogin),
        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: () => setState(() => _isLoginMode = false),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(text: 'Chưa có tài khoản? ', style: TextStyle(color: theme.textMuted)),
                  TextSpan(
                    text: 'Đăng ký ngay',
                    style: TextStyle(
                      color: theme.isDark ? ThemeService.accentLight : ThemeService.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // REGISTER FORM
  // ════════════════════════════════════════════════════════════════
  Widget _buildRegisterForm(ThemeService theme, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gamertag
        _inputLabel(theme, 'BIỆT DANH GAME (GAMERTAG / IGN)'),
        const SizedBox(height: 6),
        _inputField(theme: theme, controller: _regTagCtrl, hint: 'Ví dụ: ShadowNinja#VN1', prefixIcon: Icons.badge),
        const SizedBox(height: 16),

        // Student email
        _inputLabel(theme, 'EMAIL SINH VIÊN / LIÊN KẾT'),
        const SizedBox(height: 6),
        _inputField(theme: theme, controller: _regEmailCtrl, hint: 'ma_sinh_vien@daihoc.edu.vn', prefixIcon: Icons.school),
        const SizedBox(height: 16),

        // Password + strength
        _inputLabel(theme, 'MẬT KHẨU BẢO MẬT'),
        const SizedBox(height: 6),
        _passwordField(
          theme: theme,
          controller: _regPassCtrl,
          hint: 'Tối thiểu 8 ký tự',
          obscure: _obscureReg,
          onToggle: () => setState(() => _obscureReg = !_obscureReg),
          onChanged: _checkStrength,
        ),
        const SizedBox(height: 8),

        // 3-bar strength indicator
        Row(
          children: [
            _strengthBar(theme, 1),
            const SizedBox(width: 5),
            _strengthBar(theme, 2),
            const SizedBox(width: 5),
            _strengthBar(theme, 3),
            const SizedBox(width: 8),
            Text(
              _strengthLevel == 0 ? 'Độ an toàn' : _strengthLevel == 1 ? 'Yếu' : _strengthLevel == 2 ? 'Trung bình' : 'Rất mạnh',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _strengthLevel == 0 ? theme.textMuted : _strengthLevel == 1 ? ThemeService.red : _strengthLevel == 2 ? Colors.orange : ThemeService.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Confirm password
        _inputLabel(theme, 'XÁC NHẬN MẬT KHẨU'),
        const SizedBox(height: 6),
        _passwordField(
          theme: theme,
          controller: _regConfirmCtrl,
          hint: 'Nhập lại mật khẩu',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          prefixIcon: Icons.verified_user,
        ),
        const SizedBox(height: 16),

        // Terms
        GestureDetector(
          onTap: () => setState(() => _agreedTerms = !_agreedTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _agreedTerms,
                  activeColor: ThemeService.accent,
                  side: BorderSide(color: theme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => setState(() => _agreedTerms = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: theme.textMuted, height: 1.5),
                      children: [
                        const TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'Điều khoản BLUSH',
                          style: TextStyle(
                            color: theme.isDark ? ThemeService.accentLight : ThemeService.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' & cam kết tuân thủ '),
                        TextSpan(
                          text: 'Quy tắc Ứng xử Văn minh (Karma Code)',
                          style: TextStyle(
                            color: theme.isDark ? ThemeService.cyan : ThemeService.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Submit
        _submitBtn(theme, 'TẠO TÀI KHOẢN MỚI', Icons.bolt, _doRegister),
        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: () => setState(() => _isLoginMode = true),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(text: 'Đã có tài khoản? ', style: TextStyle(color: theme.textMuted)),
                  TextSpan(
                    text: 'Đăng nhập ngay',
                    style: TextStyle(
                      color: theme.isDark ? ThemeService.accentLight : ThemeService.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SOCIAL AUTH
  // ════════════════════════════════════════════════════════════════
  Widget _buildSocialSection(ThemeService theme) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: theme.border, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ĐĂNG NHẬP NHANH',
                style: TextStyle(color: theme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            Expanded(child: Divider(color: theme.border, thickness: 1)),
          ],
        ),
        const SizedBox(height: 12),

        // 4-column grid
        Row(
          children: [
            _socialBtn(theme, 'Discord', const Color(0xFF5865F2), _discordIcon()),
            const SizedBox(width: 8),
            _socialBtn(theme, 'Google', const Color(0xFFEA4335), _googleIcon()),
            const SizedBox(width: 8),
            _socialBtn(theme, 'Apple', theme.textPrimary, _appleIcon(theme)),
            const SizedBox(width: 8),
            _socialBtn(theme, 'Facebook', const Color(0xFF1877F2), _facebookIcon()),
          ],
        ),
      ],
    );
  }

  Widget _socialBtn(ThemeService theme, String label, Color brandColor, Widget icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label login chưa khả dụng trong bản demo.'),
            backgroundColor: ThemeService.accent,
            duration: const Duration(seconds: 2),
          ),
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: theme.isDark ? brandColor.withOpacity(0.8) : theme.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // POST-LOGIN INFO BOX
  // ════════════════════════════════════════════════════════════════
  Widget _buildPostLoginInfo(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: ThemeService.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hành Trình Tiếp Theo Của Bạn',
                style: TextStyle(
                  color: theme.isDark ? ThemeService.accentLight : ThemeService.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card: New gamer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: ThemeService.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology, color: ThemeService.accent, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Game Thủ Mới', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: ThemeService.accent, borderRadius: BorderRadius.circular(6)),
                            child: const Text('TỰ ĐỘNG', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Khảo sát AI phân loại phong cách chơi & lập hồ sơ (5 câu hỏi ngắn tìm cạ chuẩn gu, không toxic).',
                        style: TextStyle(color: theme.textMuted, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Card: Returning member
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: ThemeService.cyan.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hub, color: theme.isDark ? ThemeService.cyan : ThemeService.accent, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thành Viên Trở Lại', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.textMuted, fontSize: 12, height: 1.5),
                          children: [
                            const TextSpan(text: 'Vào thẳng '),
                            TextSpan(text: 'Dashboard Game Thủ', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
                            const TextSpan(text: ': xem AI match, nhận thưởng & nhiệm vụ hàng ngày.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TRUST BADGE
  // ════════════════════════════════════════════════════════════════
  Widget _buildTrustSection(ThemeService theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, color: theme.isDark ? ThemeService.accentLight : ThemeService.accent, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Bảo mật 100% tài khoản sinh viên & mã hóa dữ liệu',
                  style: TextStyle(color: theme.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: theme.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text('Hỗ trợ kỹ thuật 24/7', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('•', style: TextStyle(color: theme.textMuted)),
            ),
            GestureDetector(
              onTap: () {},
              child: Text('Trung tâm bảo mật', style: TextStyle(color: theme.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ════════════════════════════════════════════════════════════════
  Widget _inputLabel(ThemeService theme, String label) {
    return Text(
      label,
      style: TextStyle(color: theme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
    );
  }

  Widget _inputField({
    required ThemeService theme,
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textMuted.withOpacity(0.7), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: theme.textMuted, size: 20),
        filled: true,
        fillColor: theme.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ThemeService.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _passwordField({
    required ThemeService theme,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    IconData prefixIcon = Icons.lock,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textMuted.withOpacity(0.7), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: theme.textMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: theme.textMuted, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: theme.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ThemeService.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _strengthBar(ThemeService theme, int level) {
    Color barColor = theme.cardHigh;
    if (_strengthLevel >= level) {
      barColor = level == 1 ? ThemeService.red : level == 2 ? Colors.orange : ThemeService.green;
    }
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 4,
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _submitBtn(ThemeService theme, String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeService.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        shadowColor: ThemeService.accent.withOpacity(0.4),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Icon(icon, size: 18),
        ],
      ),
    );
  }

  // ── Social icon widgets ──────────────────────────────────────────
  Widget _discordIcon() => const Icon(Icons.discord, color: Color(0xFF5865F2), size: 20);
  Widget _googleIcon() => const Icon(Icons.g_mobiledata, color: Color(0xFFEA4335), size: 24);
  Widget _appleIcon(ThemeService theme) => Icon(Icons.apple, color: theme.textPrimary, size: 20);
  Widget _facebookIcon() => const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 20);
}
