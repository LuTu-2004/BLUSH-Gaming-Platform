import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'screens/landing_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const BlushApp(),
    ),
  );
}

class BlushApp extends StatelessWidget {
  const BlushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return MaterialApp(
      title: 'BLUSH Gaming Platform',
      debugShowCheckedModeBanner: false,
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
          return auth.isLoggedIn ? const MainNavigationScreen() : const LandingScreen();
        },
      ),
    );
  }
}
