import 'package:flutter/material.dart';

/// 🌈 UniPay brand theme
/// Colors based on:
///   Primary Purple → #6D289D9
///   Accent Yellow  → #FBBF24
/// Typography: Inter, SemiBold preferred
class AppTheme {
  // 💜 Brand Colors
  static const Color brandPrimary = Color(0xff6d289d9);
  static const Color brandAccent = Color(0xFFFBBF24);

  // ✅ Light / Dark ColorSchemes
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    primary: brandPrimary,
    secondary: brandAccent,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    primary: brandPrimary,
    secondary: brandAccent,
    brightness: Brightness.dark,
  );

  // ✅ Typography base (you can also add GoogleFonts.inter)
  static const TextStyle _titleBase =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Inter');
  static const TextStyle _subtitleBase =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'Inter');

  // ✅ Global reusable text styles
  static const TextStyle textBigBlack = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontFamily: 'Inter',
      color: Colors.black);
  static const TextStyle textMediumBlack = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      color: Colors.black87);
  static const TextStyle textSmallGrey = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: 'Inter',
      color: Colors.grey);
  static const TextStyle textWhite = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      color: Colors.white);
  static const TextStyle textAccent = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
      color: brandAccent);

  // ✅ ThemeData — Light
  static ThemeData light = ThemeData(
    colorScheme: _lightScheme,
    fontFamily: 'Inter',
    useMaterial3: true,
    scaffoldBackgroundColor: _lightScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightScheme.primary,
      foregroundColor: _lightScheme.onPrimary,
      titleTextStyle:
          _titleBase.copyWith(color: _lightScheme.onPrimary),
      toolbarTextStyle:
          _subtitleBase.copyWith(color: _lightScheme.onPrimary.withOpacity(0.8)),
      iconTheme: IconThemeData(color: _lightScheme.onPrimary),
      actionsIconTheme: IconThemeData(color: _lightScheme.onPrimary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightScheme.surface,
      selectedItemColor: brandPrimary,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
      ),
      showUnselectedLabels: true,
    ),
  );

  // ✅ ThemeData — Dark
  static ThemeData dark = ThemeData(
    colorScheme: _darkScheme,
    fontFamily: 'Inter',
    useMaterial3: true,
    scaffoldBackgroundColor: _darkScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkScheme.primary,
      foregroundColor: _darkScheme.onPrimary,
      titleTextStyle:
          _titleBase.copyWith(color: _darkScheme.onPrimary),
      toolbarTextStyle:
          _subtitleBase.copyWith(color: _darkScheme.onPrimary.withOpacity(0.8)),
      iconTheme: IconThemeData(color: _darkScheme.onPrimary),
      actionsIconTheme: IconThemeData(color: _darkScheme.onPrimary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkScheme.surface,
      selectedItemColor: brandAccent, // 🔆 pop in dark mode!
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
      ),
      showUnselectedLabels: true,
    ),
  );
}