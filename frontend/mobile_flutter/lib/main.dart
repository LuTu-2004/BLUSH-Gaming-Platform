import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'services/quest_service.dart';
import 'screens/landing_screen.dart';
import 'screens/main_navigation_screen.dart';

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
      theme: ThemeData(
        brightness: theme.isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: theme.bg,
        primaryColor: ThemeService.blurple,
        colorScheme: ColorScheme(
          brightness: theme.isDarkMode ? Brightness.dark : Brightness.light,
          primary: ThemeService.blurple,
          onPrimary: Colors.white,
          secondary: ThemeService.green,
          onSecondary: Colors.black,
          error: ThemeService.red,
          onError: Colors.white,
          surface: theme.surface,
          onSurface: theme.textPrimary,
        ),
        fontFamily: 'Roboto',
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isRestoring) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return auth.isLoggedIn ? const MainNavigationScreen() : const LandingScreen();
        },
      ),
    );
  }
}
