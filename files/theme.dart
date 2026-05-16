import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);      // Purple
  static const Color secondary = Color(0xFF03DAC6);    // Teal
  static const Color accent = Color(0xFFFF6584);       // Coral
  static const Color dark = Color(0xFF0F0E17);         // Deep dark
  static const Color cardDark = Color(0xFF1A1A2E);     // Card dark
  static const Color surface = Color(0xFF16213E);      // Surface
  static const Color textPrimary = Color(0xFFF8F8F8);
  static const Color textSecondary = Color(0xFFB0B0C0);

  // Track Colors
  static const Color dsColor = Color(0xFF6C63FF);      // Data Science - Purple
  static const Color mlColor = Color(0xFF00BFA6);      // AI/ML - Teal
  static const Color deColor = Color(0xFFFF6B6B);      // Data Engg - Coral
  static const Color daColor = Color(0xFFFFD93D);      // Data Analytics - Yellow

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: dark,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: dark,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
