import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'services/quest_service.dart';
import 'screens/admin_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        // Mở app là kiểm tra token cũ ngay -> còn hạn thì vào thẳng trang chủ
        ChangeNotifierProvider(create: (_) => AuthService(api: ApiClient())..restoreSession()),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: const BlushApp(),
    ),
  );
}

/// Tắt hiệu ứng "kéo giãn" (stretch) khi cuộn quá đầu/cuối danh sách trên Android 12+.
/// Áp dụng cho mọi màn hình vì được gắn vào MaterialApp.
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

class BlushApp extends StatelessWidget {
  const BlushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return MaterialApp(
      title: 'BLUSH Gaming Platform',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const NoStretchScrollBehavior(),
      theme: AppTheme.build(theme), // bộ quy chuẩn giao diện: lib/theme/app_theme.dart
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isRestoring) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = auth.currentUser;
          if (user == null) return const LandingScreen();
          // Gamer mới đăng ký (kể cả lần đầu đăng nhập Google) phải làm khảo sát trước
          if (user.needsOnboarding) return const OnboardingScreen();
          // Admin vào thẳng trang quản trị (trong đó có nút "Xem app người dùng")
          if (user.role == 'Admin') return const AdminScreen();
          return const MainNavigationScreen();
        },
      ),
    );
  }
}
