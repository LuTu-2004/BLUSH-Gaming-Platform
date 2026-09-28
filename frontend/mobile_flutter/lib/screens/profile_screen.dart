import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';
import 'admin_screen.dart';
import 'enable_two_factor_screen.dart';
import 'staff_screen.dart';
import 'vip_screen.dart';

/// Tab Hồ sơ: thông tin cá nhân, gói VIP, bảo mật, cài đặt, khu quản trị (Staff/Admin), đăng xuất.
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

  /// Bật: mật khẩu -> gửi mã về email -> màn nhập mã -> bật.
  /// Tắt: mật khẩu -> tắt.
  Future<void> _toggleTwoFactor(bool enable) async {
    final auth = context.read<AuthService>();
    final password = await PasswordConfirmDialog.show(
      context,
      title: enable ? 'Bật xác thực 2 bước' : 'Tắt xác thực 2 bước',
      message: enable ? 'Nhập mật khẩu để tiếp tục. BLUSH sẽ gửi 1 mã về email để chắc chắn bạn nhận được mã.' : 'Tài khoản sẽ chỉ cần mật khẩu để đăng nhập, kém an toàn hơn.',
    );
    if (password == null || !mounted) return;

    try {
      if (!enable) {
        await auth.disableTwoFactor(password);
        if (mounted) showSuccessSnack(context, 'Đã tắt xác thực 2 bước.');
        return;
      }

      await auth.startEnableTwoFactor(password);
      if (!mounted) return;
      final enabled = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => EnableTwoFactorScreen(email: auth.currentUser!.email, password: password)),
      );
      if (enabled == true && mounted) {
        showSuccessSnack(context, 'Đã bật xác thực 2 bước. Đăng nhập trên thiết bị mới sẽ cần mã từ email.');
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  void _saveProfile() {
    context.read<AuthService>().updateProfile(
          bio: _bioController.text.trim(),
          sundayAnswer: _sundayController.text.trim(),
          overthinkAnswer: _overthinkController.text.trim(),
        );
    showSuccessSnack(context, 'Đã lưu hồ sơ.');
  }

  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final user = context.watch<AuthService>().currentUser;
    final text = Theme.of(context).textTheme;
    if (user == null) return const SizedBox.shrink();

    final subtitle = [
      'Level ${user.level}',
      if (user.mbti.isNotEmpty) user.mbti,
      if (user.age != null) '${user.age} tuổi',
    ].join(' · ');

    return PageBody(
      children: [
        // ── Thông tin chính ─────────────────────────────────────
        AppCard(
          child: Row(
            children: [
              AppAvatar(
                imageUrl: user.avatarUrl,
                fallback: user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                size: 64,
                ringColor: user.isVip ? ThemeService.yellow : null,
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle, style: text.bodySmall),
                    const SizedBox(height: 2),
                    Text(user.email, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (user.isVip) ...[
                      const SizedBox(height: AppSpace.sm),
                      const TagChip('VIP', color: ThemeService.yellow, icon: Icons.workspace_premium),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // ── Gói VIP (trước đây là 1 tab riêng) ───────────────────
        AppCard(
          onTap: () => _open(const VipScreen()),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: ThemeService.yellow, size: 28),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.isVip ? 'Bạn đang dùng BLUSH Pass' : 'Nâng cấp BLUSH Pass', style: text.titleSmall),
                    Text(user.isVip ? 'Xem quyền lợi và gia hạn' : 'AI không giới hạn, ưu tiên ghép đội, từ 29K/tháng', style: text.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),

        // ── Hồ sơ hiển thị ──────────────────────────────────────
        const SectionHeader('Hồ sơ của bạn'),
        TextField(
          controller: _bioController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Giới thiệu bản thân', alignLabelWithHint: true),
        ),
        const SizedBox(height: AppSpace.md),
        // minLines/maxLines: câu trả lời dài sẽ xuống dòng thay vì bị cắt chữ
        TextField(
          controller: _sundayController,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Chủ nhật của bạn thường thế nào?'),
        ),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _overthinkController,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Điều gì khiến bạn overthink khi chơi game?'),
        ),
        const SizedBox(height: AppSpace.md),
        ElevatedButton(onPressed: _saveProfile, child: const Text('Lưu hồ sơ')),
        const SizedBox(height: AppSpace.xl),

        // ── Bảo mật ─────────────────────────────────────────────
        const SectionHeader('Bảo mật'),
        AppCard(
          padding: EdgeInsets.zero,
          child: user.hasPassword
              ? SwitchListTile(
                  value: user.twoFactorEnabled,
                  onChanged: _toggleTwoFactor,
                  secondary: const Icon(Icons.verified_user_outlined),
                  title: Text('Xác thực 2 bước qua email', style: text.titleSmall),
                  subtitle: Text(
                    user.twoFactorEnabled ? 'Đang bật: đăng nhập trên thiết bị mới cần mã từ email' : 'Yêu cầu mã từ email khi đăng nhập trên thiết bị mới',
                    style: text.bodySmall,
                  ),
                )
              : ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text('Đăng nhập bằng Google', style: text.titleSmall),
                  subtitle: Text('Tài khoản được bảo vệ bởi bảo mật của Google', style: text.bodySmall),
                ),
        ),
        const SizedBox(height: AppSpace.xl),

        // ── Cài đặt (nút sáng/tối trước đây ở thanh trên cùng) ─────
        const SectionHeader('Cài đặt'),
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            value: theme.isDark,
            onChanged: (_) => theme.toggleTheme(),
            secondary: Icon(theme.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            title: Text('Giao diện tối', style: text.titleSmall),
          ),
        ),

        // ── Khu quản trị: chỉ Staff/Admin mới thấy ───────────────
        if (user.isStaffOrAdmin) ...[
          const SizedBox(height: AppSpace.xl),
          const SectionHeader('Quản trị'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text('Kiểm duyệt (Staff)', style: text.titleSmall),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const StaffScreen()),
                ),
                if (user.role == 'Admin') ...[
                  Divider(height: 1, color: theme.border),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text('Quản trị hệ thống (Admin)', style: text.titleSmall),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(const AdminScreen()),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.xl),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: ThemeService.red, side: const BorderSide(color: ThemeService.red)),
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
          onPressed: () => context.read<AuthService>().logout(),
        ),
      ],
    );
  }
}
