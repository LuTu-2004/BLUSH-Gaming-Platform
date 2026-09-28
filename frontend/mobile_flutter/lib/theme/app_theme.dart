import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// BỘ QUY CHUẨN GIAO DIỆN (design system) của BLUSH.
/// Mọi màn hình dùng chung các giá trị ở đây -> nhìn đồng bộ, muốn đổi chỉ sửa 1 chỗ.
///
/// Cách dùng trong màn hình:
///   Text('Tiêu đề', style: Theme.of(context).textTheme.titleLarge)
///   SizedBox(height: AppSpace.md)
///   ElevatedButton(...)   // tự lấy màu, bo góc, cỡ chữ từ theme
class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Lề 2 bên của nội dung màn hình
  static const EdgeInsets page = EdgeInsets.fromLTRB(lg, lg, lg, xl);
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class AppTheme {
  /// Tạo ThemeData theo chế độ sáng/tối hiện tại.
  static ThemeData build(ThemeService t) {
    final isDark = t.isDark;
    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: ThemeService.accent,
      onPrimary: Colors.white,
      primaryContainer: isDark ? ThemeService.accentContainer : const Color(0xFFEDE4FF),
      onPrimaryContainer: isDark ? ThemeService.accentLight : ThemeService.accent,
      secondary: ThemeService.green,
      onSecondary: Colors.black,
      error: ThemeService.red,
      onError: Colors.white,
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textMuted,
      outline: t.border,
      outlineVariant: t.border,
      surfaceContainerHighest: t.cardHigh,
    );

    // Thang cỡ chữ: chỉ dùng các cỡ này, không tự đặt fontSize lung tung trong màn hình
    final text = TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25, color: t.textPrimary),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3, color: t.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35, color: t.textPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.35, color: t.textPrimary),
      bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: t.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: t.textPrimary),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: t.textMuted),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted),
    );

    final roundedMd = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: c, width: w));

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      fontFamily: 'Roboto',
      textTheme: text,
      dividerColor: t.border,
      appBarTheme: AppBarTheme(
        backgroundColor: t.header,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: t.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: t.border)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeService.accent,
          foregroundColor: Colors.white, // chữ trắng trên nền tím: đủ độ tương phản
          disabledBackgroundColor: t.cardHigh,
          disabledForegroundColor: t.textMuted,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          shape: roundedMd,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          side: BorderSide(color: t.border),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          shape: roundedMd,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? ThemeService.accentLight : ThemeService.accent,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 14),
        hintStyle: TextStyle(color: t.textMuted.withValues(alpha: 0.7)),
        labelStyle: TextStyle(color: t.textMuted),
        border: inputBorder(t.border),
        enabledBorder: inputBorder(t.border),
        focusedBorder: inputBorder(ThemeService.accent, 1.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.card,
        selectedColor: ThemeService.accent,
        side: BorderSide(color: t.border),
        labelStyle: text.labelMedium!.copyWith(color: t.textPrimary),
        secondaryLabelStyle: text.labelMedium!.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : t.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? ThemeService.accent : t.cardHigh),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.header,
        indicatorColor: ThemeService.accent.withValues(alpha: isDark ? 0.28 : 0.14),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? t.textPrimary : t.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? (isDark ? ThemeService.accentLight : ThemeService.accent) : t.textMuted),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textMuted,
        textColor: t.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dialogTheme: DialogThemeData(backgroundColor: t.surface),
    );
  }
}
