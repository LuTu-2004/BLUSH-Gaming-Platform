import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'match_feed_screen.dart';
import 'profile_screen.dart';
import 'quests_screen.dart';

/// Khung chính sau khi đăng nhập: thanh trên cùng + 5 tab ở dưới.
/// (Hướng dẫn thiết kế Material: thanh điều hướng dưới nên có 3–5 mục.)
/// VIP, sáng/tối, Staff/Admin, đăng xuất nằm trong tab Hồ sơ.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _goTo(int index) => setState(() => _currentIndex = index);

  // late: tạo 1 lần (giữ trạng thái từng tab), Trang chủ nhận hàm để chuyển tab
  late final List<Widget> _screens = [
    DashboardScreen(onNavigate: _goTo),
    const MatchFeedScreen(),
    const LeaderboardScreen(),
    const QuestsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final user = context.watch<AuthService>().currentUser;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpace.lg,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (_, __, ___) => Text('BLUSH', style: text.titleLarge),
            ),
            const Spacer(),
            // Level + Coins gộp thành 1 viên, bấm vào mở tab Hồ sơ
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => _goTo(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lv.${user?.level ?? 1}', style: text.labelLarge),
                    const SizedBox(width: AppSpace.sm),
                    const Icon(Icons.monetization_on, size: 16, color: ThemeService.yellow),
                    const SizedBox(width: 4),
                    Text('${user?.coins ?? 0}', style: text.labelLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chưa có thông báo mới.')),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      // IndexedStack: giữ nguyên trạng thái từng tab khi chuyển qua lại
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Đồng đội'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Xếp hạng'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'Nhiệm vụ'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
