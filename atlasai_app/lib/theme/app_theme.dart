import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandBlue = Color(0xFF004A99);
  // Shared light surfaces and Paytm-inspired brand colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFEDF6FC);
  static const Color tealPrimary = Color(0xFF00B4D8);
  static const Color cyanAccent = Color(0xFF0079BC);
  static const Color amberWarning = Color(0xFF9A6400);
  static const Color emeraldSuccess = Color(0xFF12835B);
  static const Color roseDanger = Color(0xFFD43546);

  static const Color textPrimary = Color(0xFF17191C);
  static const Color textMuted = Color(0xFF657382);
  static const Color borderSubtle = Color(0xFFE5EBF0);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: brandBlue,
        secondary: cyanAccent,
        surface: surface,
        error: roseDanger,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceTint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tealPrimary, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
