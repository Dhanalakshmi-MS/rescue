import 'package:flutter/material.dart';

class AppTheme {
  // Primary Palette - Dark Navy & High-Visibility Accents
  static const Color background = Color(0xFF0A111E);
  static const Color surface = Color(0xFF132032);
  static const Color surfaceLight = Color(0xFF1E314B);
  static const Color cardBorder = Color(0xFF223652);
  
  static const Color primaryBlue = Color(0xFF0077B6);
  static const Color cyanAccent = Color(0xFF00B4D8);
  
  // Emergency Status Colors
  static const Color dangerRed = Color(0xFFE53935);
  static const Color dangerGlow = Color(0xFFFF5252);
  static const Color warningAmber = Color(0xFFFFB300);
  static const Color safeGreen = Color(0xFF43A047);
  static const Color safeGlow = Color(0xFF66BB6A);
  static const Color neutralGrey = Color(0xFF78909C);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF607D8B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      canvasColor: surface,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: cyanAccent,
        unselectedItemColor: neutralGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: cyanAccent,
        surface: surface,
        error: dangerRed,
      ),
    );
  }
}
