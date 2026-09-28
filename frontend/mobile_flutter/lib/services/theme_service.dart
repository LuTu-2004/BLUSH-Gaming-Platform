import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;
  bool get isDark => _isDarkMode;

  // ── Brand Accent (constant across both modes) ─────────────────────
  static const Color accent = Color(0xFF7C3AED); // Purple primary
  static const Color accentLight = Color(0xFFD2BBFF); // Purple light
  static const Color accentContainer = Color(0xFF4F319C); // Purple container
  static const Color green = Color(0xFF4ADE80);
  static const Color yellow = Color(0xFFFFC700);
  static const Color cyan = Color(0xFF00EEFC);
  static const Color pink = Color(0xFFFFB1C5);
  static const Color red = Color(0xFFED4245);

  // Legacy aliases (used in older screens)
  static const Color blurple = Color(0xFF7C3AED);
  static const Color fuchsia = Color(0xFFEB459E);

  // ── Dark Mode Tokens ──────────────────────────────────────────────
  static const Color _darkBg = Color(0xFF13131B);
  static const Color _darkSurface = Color(0xFF1B1B23);
  static const Color _darkCard = Color(0xFF1F1F27);
  static const Color _darkCardHigh = Color(0xFF292932);
  static const Color _darkBorder = Color(0xFF2E2E3A);
  static const Color _darkText = Color(0xFFE4E1ED);
  static const Color _darkTextMuted = Color(0xFFCCC3D8);
  static const Color _darkHeader = Color(0xFF0D0D15);

  // ── Light Mode Tokens ─────────────────────────────────────────────
  static const Color _lightBg = Color(0xFFF5F5FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightCardHigh = Color(0xFFEEEEF8);
  static const Color _lightBorder = Color(0xFFE0DFF0);
  static const Color _lightText = Color(0xFF1A1A2E);
  static const Color _lightTextMuted = Color(0xFF6B6880);
  static const Color _lightHeader = Color(0xFFEBEBF5);

  // ── Adaptive Getters ──────────────────────────────────────────────
  Color get bg => _isDarkMode ? _darkBg : _lightBg;
  Color get surface => _isDarkMode ? _darkSurface : _lightSurface;
  Color get card => _isDarkMode ? _darkCard : _lightCard;
  Color get cardHigh => _isDarkMode ? _darkCardHigh : _lightCardHigh;
  Color get border => _isDarkMode ? _darkBorder : _lightBorder;
  Color get header => _isDarkMode ? _darkHeader : _lightHeader;
  Color get textPrimary => _isDarkMode ? _darkText : _lightText;
  Color get textMuted => _isDarkMode ? _darkTextMuted : _lightTextMuted;
  Color get textOnAccent => Colors.white;

  // Divider / subtle separator
  Color get divider => _isDarkMode ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);

  // ── Hero gradient (used in Dashboard banner) ──────────────────────
  List<Color> get heroBannerGradient => _isDarkMode ? [const Color(0xFF1A0533), const Color(0xFF13131B)] : [const Color(0xFF6D28D9), const Color(0xFF7C3AED)];

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
