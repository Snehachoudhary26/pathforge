import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary    = Color(0xFF8B53EC);
  static const Color light      = Color(0xFFEDE9FE);
  static const Color background = Color(0xFFF8F7FF);
  static const Color cardWhite  = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE4DCFB);
  static const Color textDark   = Color(0xFF1A0A3A);
  static const Color textMid    = Color(0xFF6B5A8A);
  static const Color textLight  = Color(0xFFAA99C0);
  static const Color dsColor    = Color(0xFF8B53EC);
  static const Color mlColor    = Color(0xFF6B35CC);
  static const Color deColor    = Color(0xFFAA75F0);
  static const Color daColor    = Color(0xFFC49DF5);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      surface: cardWhite,
      onPrimary: Colors.white,
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: textDark,
      displayColor: textDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    ),
  );
}
