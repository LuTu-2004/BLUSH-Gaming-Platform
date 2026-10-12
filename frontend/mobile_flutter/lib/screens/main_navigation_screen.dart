import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/quest_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'community_screen.dart';
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
  // Số trên 🔔 / 💬, sống cùng khung chính (đăng xuất thì khung chính bị bỏ -> tự đóng kết nối)
  late final NotificationCenter _notifications = NotificationCenter(context.read<AuthService>());

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _notifications.refresh(); // vừa đọc tin / thông báo
  }

  void _goTo(int index) {
    // Mở tab Nhiệm vụ -> tải lại tiến độ (VD: vừa xem gợi ý ở tab Đồng đội thì "Ghép đội 1 lần" đã xong)
    if (index == 3 && index != _currentIndex) context.read<QuestService>().load(context.read<AuthService>());
    setState(() => _currentIndex = index);
  }

  // late: tạo 1 lần (giữ trạng thái từng tab), Trang chủ nhận hàm để chuyển tab
  late final List<Widget> _screens = [
    DashboardScreen(onNavigate: _goTo),
    const MatchFeedScreen(),
    const CommunityScreen(),
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
          ListenableBuilder(
            listenable: _notifications,
            builder: (context, _) => IconButton(
              tooltip: 'Tin nhắn',
              icon: Badge(
                isLabelVisible: _notifications.unreadChats > 0,
                label: Text('${_notifications.unreadChats}'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              onPressed: () => _openAndRefresh(const ChatListScreen()),
            ),
          ),
          ListenableBuilder(
            listenable: _notifications,
            builder: (context, _) => IconButton(
              tooltip: 'Thông báo',
              icon: Badge(
                isLabelVisible: _notifications.unreadNotifications > 0,
                label: Text(_notifications.unreadNotifications > 99 ? '99+' : '${_notifications.unreadNotifications}'),
                child: const Icon(Icons.notifications_none),
              ),
              onPressed: () => _openAndRefresh(const NotificationsScreen()),
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
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Cộng đồng'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'Nhiệm vụ'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
