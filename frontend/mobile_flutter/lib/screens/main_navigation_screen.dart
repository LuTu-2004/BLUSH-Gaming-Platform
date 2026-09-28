import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'match_feed_screen.dart';
import 'leaderboard_screen.dart';
import 'quests_screen.dart';
import 'vip_screen.dart';
import 'profile_screen.dart';
import 'staff_screen.dart';
import 'admin_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MatchFeedScreen(),
    LeaderboardScreen(),
    QuestsScreen(),
    VipScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final user = context.watch<AuthService>().currentUser;

    const primaryPurple = ThemeService.accent;
    final accentText = theme.isDark ? ThemeService.accentLight : primaryPurple;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.header.withValues(alpha: 0.95),
        elevation: 0,
        titleSpacing: 12,
        // FittedBox: màn hình hẹp thì thu nhỏ logo + huy hiệu thay vì bị tràn
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo & Brand Name
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
                        letterSpacing: 1.2,
                        color: accentText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Level & Coins của người dùng đang đăng nhập
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, color: accentText, size: 13),
                    const SizedBox(width: 4),
                    Text('Lv.${user?.level ?? 1}', style: TextStyle(color: accentText, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: accentText, size: 13),
                    const SizedBox(width: 4),
                    Text('${user?.coins ?? 0}', style: TextStyle(color: accentText, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Theme Toggle Button (Dark / Light mode)
          IconButton(
            tooltip: theme.isDark ? 'Chuyển Chế Độ Sáng' : 'Chuyển Chế Độ Tối',
            icon: Icon(
              theme.isDark ? Icons.light_mode : Icons.dark_mode,
              color: theme.isDark ? Colors.amber : primaryPurple,
            ),
            onPressed: () {
              theme.toggleTheme();
            },
          ),

          // Notification Bell with badge dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Thông báo nhanh',
                icon: Icon(Icons.notifications_none, color: theme.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không có thông báo mới.')),
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          // Role Switcher & Account Menu
          PopupMenuButton<String>(
            tooltip: 'Đổi Vai Trò & Tài Khoản',
            icon: Icon(Icons.shield_outlined, color: accentText),
            onSelected: (role) {
              if (role == 'Logout') {
                context.read<AuthService>().logout();
              } else if (role == 'Staff') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffScreen()));
              } else if (role == 'Admin') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Gamer', child: Text('👤 ${user?.displayName ?? ''} (${user?.role ?? 'User'})')),
              // Chỉ Staff/Admin mới thấy các trang quản trị (backend cũng phải kiểm tra role khi có API)
              if (user?.isStaffOrAdmin == true) const PopupMenuItem(value: 'Staff', child: Text('🛡️ Staff Portal')),
              if (user?.role == 'Admin') const PopupMenuItem(value: 'Admin', child: Text('⚡ Admin Panel')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('🚪 Đăng Xuất Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),

          // User Avatar pill with status dot
          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 5; // Switch to Profile screen
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12, left: 4),
              child: Stack(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryPurple.withValues(alpha: 0.6), width: 1.5),
                      color: theme.cardHigh,
                    ),
                    child: const Center(
                      child: Text('⚡', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.header, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: theme.header,
        selectedItemColor: primaryPurple,
        unselectedItemColor: theme.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.space_dashboard), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Tìm Zone'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Bảng Xếp Hạng'),
          BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: 'Nhiệm Vụ'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'VIP Pass'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ Sơ'),
        ],
      ),
    );
  }
}
