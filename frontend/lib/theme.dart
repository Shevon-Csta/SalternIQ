import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ─────────────────────────────────────────
  static const Color primary     = Color(0xFF0A6E5C);   // deep teal
  static const Color primaryDark = Color(0xFF064D41);
  static const Color accent      = Color(0xFFE8A826);   // warm amber (salt crystal)
  static const Color surface     = Color(0xFFF5F7F6);
  static const Color card        = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF1A2E2B);
  static const Color textMid     = Color(0xFF4A6B65);
  static const Color textLight   = Color(0xFF8AADA8);
  static const Color viable      = Color(0xFF2E9E6B);
  static const Color notViable   = Color(0xFFD94F3D);
  static const Color border      = Color(0xFFDDE8E6);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32, fontWeight: FontWeight.w700, color: textDark,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 26, fontWeight: FontWeight.w600, color: textDark,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 20, fontWeight: FontWeight.w700, color: textDark,
      ),
      bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: textDark),
      bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: textMid),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: GoogleFonts.dmSans(color: textMid),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
  );
}
