import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'admin/admin_cost_page.dart';
import 'admin/admin_overview_page.dart';
import 'admin/admin_transactions_page.dart';
import 'admin/admin_users_page.dart';
import 'admin/admin_widgets.dart';
import 'main_navigation_screen.dart';

/// Trang quản trị (Admin) - tài khoản Admin đăng nhập là vào thẳng đây (main.dart).
///   Màn rộng (>= 900px): menu cố định bên trái + thanh tiêu đề
///   Màn hẹp: menu trong ngăn kéo (nút ☰)
/// Trang con nằm trong lib/screens/admin/.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminSection {
  final IconData icon;
  final String label;
  final String subtitle;

  const _AdminSection(this.icon, this.label, this.subtitle);
}

class _AdminScreenState extends State<AdminScreen> {
  static const _sections = [
    _AdminSection(Icons.dashboard_outlined, 'Tổng quan', 'Doanh thu và hoạt động của BLUSH'),
    _AdminSection(Icons.receipt_long_outlined, 'Giao dịch', 'Tra cứu, lọc và xác nhận thanh toán'),
    _AdminSection(Icons.people_outline, 'Người dùng', 'Quản lý tài khoản thành viên'),
    _AdminSection(Icons.calculate_outlined, 'Chi phí', 'Mô phỏng chi phí vận hành và lợi nhuận'),
  ];

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  // IndexedStack giữ trạng thái từng trang khi chuyển qua lại (không tải lại)
  late final List<Widget> _pages = [
    AdminOverviewPage(onNavigate: _goTo),
    const AdminTransactionsPage(),
    const AdminUsersPage(),
    const AdminCostPage(),
  ];

  void _goTo(int index) {
    setState(() => _index = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }

  void _openUserApp() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final wide = isWideAdmin(context);
    final sidebar = _Sidebar(sections: _sections, selected: _index, onSelect: _goTo, onOpenUserApp: _openUserApp);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: t.bg,
      drawer: wide ? null : Drawer(backgroundColor: t.header, child: SafeArea(child: sidebar)),
      body: Row(
        children: [
          if (wide) SizedBox(width: 248, child: Material(color: t.header, child: SafeArea(child: sidebar))),
          if (wide) VerticalDivider(width: 1, color: t.border),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  section: _sections[_index],
                  onMenu: wide ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(child: IndexedStack(index: _index, children: _pages)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu bên trái ───────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_AdminSection> sections;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenUserApp;

  const _Sidebar({required this.sections, required this.selected, required this.onSelect, required this.onOpenUserApp});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final user = context.watch<AuthService>().currentUser;
    final text = Theme.of(context).textTheme;
    final accent = t.isDark ? ThemeService.accentLight : ThemeService.accent;

    Widget item(IconData icon, String label, {required bool active, required VoidCallback onTap, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 2),
          child: Material(
            color: active ? ThemeService.accent.withValues(alpha: t.isDark ? 0.28 : 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: color ?? (active ? accent : t.textMuted)),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        label,
                        style: text.bodyMedium?.copyWith(color: color ?? (active ? t.textPrimary : t.textMuted), fontWeight: active ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo + nhãn khu quản trị
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
          child: Row(
            children: [
              Flexible(
                child: Image.asset('assets/images/logo.png', height: 34, errorBuilder: (_, __, ___) => Text('BLUSH', style: text.titleLarge)),
              ),
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
                decoration: BoxDecoration(color: ThemeService.accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xs),
          child: Text('QUẢN LÝ', style: text.labelSmall?.copyWith(letterSpacing: 1)),
        ),
        for (var i = 0; i < sections.length; i++) item(sections[i].icon, sections[i].label, active: i == selected, onTap: () => onSelect(i)),
        const Spacer(),
        Divider(height: 1, color: t.border),
        const SizedBox(height: AppSpace.sm),
        item(Icons.phone_iphone, 'Xem app người dùng', active: false, onTap: onOpenUserApp),
        item(t.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, t.isDark ? 'Giao diện sáng' : 'Giao diện tối', active: false, onTap: t.toggleTheme),
        item(Icons.logout, 'Đăng xuất', active: false, onTap: () => context.read<AuthService>().logout(), color: ThemeService.red),
        if (user != null)
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                AppAvatar(imageUrl: user.avatarUrl, fallback: user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'A', size: 36),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(user.email, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Thanh tiêu đề trang ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final _AdminSection section;
  final VoidCallback? onMenu; // null = màn rộng, đã có menu bên trái

  const _TopBar({required this.section, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    const weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];

    return Material(
      color: t.header,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: onMenu == null ? AppSpace.xl : AppSpace.sm),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
          child: Row(
            children: [
              if (onMenu != null) IconButton(tooltip: 'Menu', icon: const Icon(Icons.menu), onPressed: onMenu),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.label, style: text.titleLarge),
                    Text(section.subtitle, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (onMenu == null)
                Text('${weekdays[now.weekday - 1]}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}', style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
