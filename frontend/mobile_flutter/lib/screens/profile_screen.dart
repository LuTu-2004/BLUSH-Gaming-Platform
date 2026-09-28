import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bioController = TextEditingController();
  final _overthinkController = TextEditingController();
  final _sundayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Điền sẵn dữ liệu hiện tại của người dùng vào form
    final user = context.read<AuthService>().currentUser;
    _bioController.text = user?.bio ?? '';
    _sundayController.text = user?.sundayAnswer ?? '';
    _overthinkController.text = user?.overthinkAnswer ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    _overthinkController.dispose();
    _sundayController.dispose();
    super.dispose();
  }

  /// Bật/tắt xác thực 2 bước: hỏi lại mật khẩu rồi gọi API
  Future<void> _toggleTwoFactor(bool enable) async {
    final password = await _askPassword(enable);
    if (password == null || !mounted) return;
    try {
      await context.read<AuthService>().setTwoFactor(enabled: enable, password: password);
      if (mounted) {
        showSuccessSnack(context, enable ? 'Đã bật xác thực 2 bước. Lần đăng nhập sau sẽ cần mã từ email.' : 'Đã tắt xác thực 2 bước.');
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  Future<String?> _askPassword(bool enable) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(enable ? 'Bật xác thực 2 bước' : 'Tắt xác thực 2 bước'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(enable ? 'Mỗi lần đăng nhập trên thiết bị mới, BLUSH sẽ gửi mã 6 số về email của bạn.' : 'Tài khoản sẽ chỉ cần mật khẩu để đăng nhập, kém an toàn hơn.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nhập mật khẩu hiện tại'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Xác nhận')),
        ],
      ),
    ).whenComplete(ctrl.dispose);
  }

  void _saveProfile() {
    context.read<AuthService>().updateProfile(
          bio: _bioController.text.trim(),
          sundayAnswer: _sundayController.text.trim(),
          overthinkAnswer: _overthinkController.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật hồ sơ cá nhân thành công! 🎉')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar & Level Header Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ThemeService.blurple.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeService.blurple.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ThemeService.yellow, width: 2.5),
                        ),
                        child: const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0x335865F2),
                          child: Text('🎮', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? '',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                [
                                  'Level ${user?.level ?? 1}',
                                  if (user != null && user.mbti.isNotEmpty) user.mbti,
                                  if (user?.isVip == true) '👑 VIP',
                                ].join(' • '),
                                style: const TextStyle(color: ThemeService.blurple, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: ThemeService.yellow.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: ThemeService.yellow.withValues(alpha: 0.3))),
                                    child: const Text('🥇 Top 1 Tấu Hài', style: TextStyle(color: ThemeService.yellow, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: ThemeService.blurple.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: ThemeService.blurple.withValues(alpha: 0.3))),
                                    child: const Text('👑 Local MVP', style: TextStyle(color: ThemeService.blurple, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: ThemeService.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: ThemeService.green.withValues(alpha: 0.3))),
                                    child: const Text('🛡️ Mod Cần Mẫn', style: TextStyle(color: ThemeService.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Form Section
                Text('📝 CHỈNH SỬA THÔNG TIN & PROMPT TÍNH CÁCH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: theme.textPrimary)),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ThemeService.blurple.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _bioController,
                        maxLines: 2,
                        style: TextStyle(color: theme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Bio Giới Thiệu Bản Thân',
                          labelStyle: TextStyle(color: theme.textMuted),
                          prefixIcon: const Icon(Icons.person_pin, color: ThemeService.blurple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _sundayController,
                        style: TextStyle(color: theme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Chủ nhật của bạn thường trông như thế nào?',
                          labelStyle: TextStyle(color: theme.textMuted),
                          prefixIcon: const Icon(Icons.wb_sunny, color: ThemeService.yellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _overthinkController,
                        style: TextStyle(color: theme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Điều gì khiến bạn overthink nhất khi chơi game?',
                          labelStyle: TextStyle(color: theme.textMuted),
                          prefixIcon: const Icon(Icons.psychology, color: ThemeService.fuchsia),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeService.blurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('LƯU THÔNG TIN HỒ SƠ ➔', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          onPressed: _saveProfile,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bảo mật: xác thực 2 bước (chỉ tài khoản có mật khẩu; tài khoản Google đã được Google bảo vệ)
                      if (user != null && user.hasPassword) ...[
                        // Material (không dùng Container màu nền) để hiệu ứng khi bấm hiện được
                        Material(
                          color: theme.card,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: theme.border),
                          ),
                          child: SwitchListTile(
                            value: user.twoFactorEnabled,
                            onChanged: _toggleTwoFactor,
                            activeThumbColor: ThemeService.accent,
                            secondary: const Icon(Icons.verified_user_outlined, color: ThemeService.accent),
                            title: Text('Xác thực 2 bước qua email', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              user.twoFactorEnabled ? 'Đang bật: đăng nhập trên thiết bị mới cần mã từ email' : 'Tăng bảo mật: yêu cầu mã từ email khi đăng nhập',
                              style: TextStyle(color: theme.textMuted, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Logout Account Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: const Text('ĐĂNG XUẤT TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent)),
                          onPressed: () {
                            context.read<AuthService>().logout();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
