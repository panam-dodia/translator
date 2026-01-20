import 'package:flutter/material.dart';

class ThemeConfig {
  // Minimal color palette - Startup aesthetic
  static const Color primaryDark = Color(0xFF0f172a);
  static const Color primaryAccent = Color(0xFF3b82f6);
  static const Color backgroundColor = Color(0xFFffffff);

  // Neutral shades
  static const Color surfaceColor = Color(0xFFf8fafc);
  static const Color borderColor = Color(0xFFe2e8f0);

  // Text colors
  static const Color textPrimaryColor = Color(0xFF0f172a);
  static const Color textSecondaryColor = Color(0xFF64748b);
  static const Color textTertiaryColor = Color(0xFF94a3b8);

  // User section colors (minimal)
  static const Color user1Background = Color(0xFF0f172a);
  static const Color user2Background = Color(0xFF1e293b);

  // App theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryAccent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: textPrimaryColor,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 0,
      backgroundColor: primaryDark,
    ),
  );

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textSecondaryColor,
    letterSpacing: 0.5,
  );

  static const TextStyle messageOriginalStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle messageTranslatedStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
    height: 1.5,
  );
}
