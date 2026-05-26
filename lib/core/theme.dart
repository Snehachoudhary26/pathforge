import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New premium palette
  static const Color primary     = Color(0xFF7C5CBF); // rich purple
  static const Color orange      = Color(0xFFFF6B35); // action orange
  static const Color navy        = Color(0xFF1A1A2E); // deep navy
  static const Color cream       = Color(0xFFFAFAF8); // warm white
  static const Color background  = Color(0xFFF0EDF8); // soft lavender bg
  static const Color cardWhite   = Color(0xFFFFFFFF);
  static const Color border      = Color(0xFFEDE9F8);
  static const Color textDark    = Color(0xFF1A1A2E);
  static const Color textMid     = Color(0xFF6B6890);
  static const Color textLight   = Color(0xFF9B99B5);

  // Semantic
  static const Color green       = Color(0xFF2E7D32);
  static const Color greenLight  = Color(0xFFE8F5E9);
  static const Color greenBorder = Color(0xFFC8E6C9);
  static const Color amber       = Color(0xFFF57F17);
  static const Color amberLight  = Color(0xFFFFF8E1);
  static const Color amberBorder = Color(0xFFFFECB3);
  static const Color orangeLight = Color(0xFFFFF3E0);
  static const Color orangeBorder= Color(0xFFFFE0B2);
  static const Color purpleLight = Color(0xFFF5F3FF);
  static const Color purpleBorder= Color(0xFFDDD8F8);

  // Legacy aliases so old screens don't break
  static const Color light    = Color(0xFFF5F3FF);
  static const Color dsColor  = Color(0xFF7C5CBF);
  static const Color mlColor  = Color(0xFF6B35CC);
  static const Color deColor  = Color(0xFF2E7D32);
  static const Color daColor  = Color(0xFFFF6B35);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      surface: cardWhite,
      onPrimary: Colors.white,
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: cream,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: textDark, displayColor: textDark),
    appBarTheme: AppBarTheme(
      backgroundColor: cream,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: textDark, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 0,
      ),
    ),
  );
}
