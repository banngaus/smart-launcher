import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Colors ───
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF22D3EE);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // ─── Backgrounds ───
  static const Color bgDark = Color(0xFF0F0F23);
  static const Color bgCard = Color(0xFF1A1A2E);
  static const Color bgCardHover = Color(0xFF252542);
  static const Color bgSurface = Color(0xFF16162A);
  static const Color bgConsole = Color(0xFF0A0A14);
  static const Color bgModal = Color(0xFF0D0D1A);

  // ─── Text ───
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // ─── Borders ───
  static Color get borderSubtle => Colors.white.withValues(alpha: 0.05);
  static Color get borderLight => Colors.white.withValues(alpha: 0.1);
  static Color get borderMedium => Colors.white.withValues(alpha: 0.2);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme ───
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: bgSurface,
        error: errorColor,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textMuted),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderSubtle),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderLight),
        ),
      ),
    );
  }
}