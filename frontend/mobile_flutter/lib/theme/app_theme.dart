import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors matching Vercel CSS Tokens 100%
  static const Color bgDark = Color(0xFF0A0516);
  static const Color surface = Color(0xFF140E28);
  static const Color surface2 = Color(0xFF182C3D);
  static const Color surface3 = Color(0xFF221740);

  static const Color cyan = Color(0xFF00F5FF);
  static const Color purple = Color(0xFF9D4EDD);
  static const Color pink = Color(0xFFFF4D6D);
  static const Color greenSuccess = Color(0xFF00FF9F);
  static const Color gold = Color(0xFFFFB703);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0C0);
  static const Color textMuted = Color(0xFF6C6C8A);

  // Vercel Brand Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF00F5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF221740), Color(0xFF140E28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonPinkGradient = LinearGradient(
    colors: [Color(0xFFFF4D6D), Color(0xFF9D4EDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neon Shadows
  static List<BoxShadow> neonGlow(Color color, {double opacity = 0.4, double blurRadius = 15}) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blurRadius,
        spreadRadius: 1,
      ),
    ];
  }

  // Glassmorphism Card Decoration matching Vercel
  static BoxDecoration glassDecoration({Color borderAccent = purple, double opacity = 0.7}) {
    return BoxDecoration(
      color: surface.withOpacity(opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderAccent.withOpacity(0.35),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: cyan,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: purple,
        surface: surface,
      ),
      fontFamily: 'Roboto',
    );
  }
}
