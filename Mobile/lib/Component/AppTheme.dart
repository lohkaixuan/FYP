// ==================================================
// Program Name   : AppTheme.dart
// Purpose        : Application theme configuration
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';

class AppTheme {

  // Brand gradient: Purple -> Indigo
  static const Color cPurple600 = Color(0xFF6D28D9);
  static const Color cIndigo500 = Color(0xFF4655F7);
  static const Color cIndigo400 = Color(0xFF7C8CFD);

  // Neutrals & Dark surfaces (from the style board)
  static const Color cNeutral700 = Color(0xFF2C2C33);
  static const Color cNeutral500 = Color(0xFF6B7280);
  static const Color cDarkStroke = Color(0xFF23293D);
  static const Color cDarkFill   = Color(0xFF0B0B12);
  static const Color cDarkFillAlt= Color(0xFF131826); // inputs / cards

  // Accent / states
  static const Color cSuccess = Color(0xFF23D18B);
  static const Color cWarning = Color(0xFFFFC857);
  static const Color cError   = Color(0xFFEF476F);

  // Gradient
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cPurple600, cIndigo500],
  );

  // Back-compat aliases for existing code
  static const Color brandPrimary = cIndigo500;
  static const Color brandAccent = cIndigo400;
  static const LinearGradient primaryGradient = brandGradient;

  // =========================
  //Radius & Elevation
  // =========================
  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 20;

  // =========================
  // Typography (Outfit)
  // Keep it tight & modern like the kit
  // =========================
  static const String _font = 'Outfit';

  static TextTheme _textThemeLight(Color onBg) => const TextTheme(
    displayLarge:   TextStyle(fontFamily: _font, fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    displayMedium:  TextStyle(fontFamily: _font, fontSize: 36, fontWeight: FontWeight.w700),
    headlineLarge:  TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w600),
    titleLarge:     TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium:    TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall:     TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge:      TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w500, height: 1.25),
    bodyMedium:     TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 1.3),
    bodySmall:      TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400, height: 1.3),
    labelLarge:     TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium:    TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall:     TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600),
  ).apply(bodyColor: onBg, displayColor: onBg);

  static TextTheme _textThemeDark(Color onBg) =>
      _textThemeLight(onBg); // same sizes, just different color via apply

  // =========================
  // Light Scheme
  // =========================
  static final ColorScheme _light = ColorScheme(
    brightness: Brightness.light,
    primary: cIndigo500,
    onPrimary: Colors.white,
    secondary: cIndigo400,
    onSecondary: Colors.white,
    error: cError,
    onError: Colors.white,
    background: Colors.white,
    onBackground: cNeutral700,
    surface: Colors.white,
    onSurface: cNeutral700,
    surfaceVariant: const Color(0xFFF6F7FB),
    onSurfaceVariant: cNeutral500,
    outline: const Color(0xFFE6E8EF),
    shadow: Colors.black.withOpacity(.25),
    tertiary: cSuccess,
    onTertiary: Colors.white,
  );

  // =========================
  // Dark Scheme
  // =========================
  static final ColorScheme _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: cIndigo500,
    onPrimary: Colors.white,
    secondary: cIndigo400,
    onSecondary: Colors.white,
    error: cError,
    onError: Colors.white,
    background: cDarkFill,
    onBackground: Colors.white,
    surface: cDarkStroke,
    onSurface: Colors.white,
    surfaceVariant: cDarkFillAlt,
    onSurfaceVariant: Colors.white70,
    outline: const Color(0xFF2F3650),
    shadow: Colors.black.withOpacity(.6),
    tertiary: cSuccess,
    onTertiary: Colors.black,
  );

  // =========================
  // Widgets  shared styles
  // =========================
  static RoundedRectangleBorder _rounded(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

  // =========================
  // ThemeData (Light)
  // =========================
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: _light,
    scaffoldBackgroundColor: _light.background,
    fontFamily: _font,
    textTheme: _textThemeLight(_light.onBackground),

    appBarTheme: AppBarTheme(
      backgroundColor: _light.background,
      foregroundColor: _light.onBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _textThemeLight(_light.onBackground).titleLarge,
    ),

    cardTheme: CardThemeData(
      color: _light.surface,
      elevation: 1,
      shadowColor: _light.shadow,
      shape: _rounded(rMd),
      margin: const EdgeInsets.all(12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _light.primary,
        foregroundColor: _light.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: _rounded(rMd),
        textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _light.secondary,
        foregroundColor: _light.onSecondary,
        minimumSize: const Size.fromHeight(48),
        shape: _rounded(rMd),
        textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _light.primary,
        textStyle: const TextStyle(
          fontFamily: _font, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _light.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(rMd), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: BorderSide(color: _light.primary, width: 1.6),
      ),
      hintStyle: TextStyle(color: _light.onSurfaceVariant),
      labelStyle: TextStyle(color: _light.onSurface),
    ),

    chipTheme: ChipThemeData(
      labelStyle: TextStyle(color: _light.onSurface),
      backgroundColor: _light.surfaceVariant,
      selectedColor: _light.primary.withOpacity(.12),
      secondarySelectedColor: _light.secondary.withOpacity(.12),
      shape: _rounded(rSm),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: _light.surface,
      surfaceTintColor: Colors.transparent,
      shape: _rounded(rLg),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _light.surface,
      contentTextStyle: TextStyle(color: _light.onSurface),
      actionTextColor: _light.primary,
      behavior: SnackBarBehavior.floating,
      shape: _rounded(rSm),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _light.background,
      selectedItemColor: _light.primary,
      unselectedItemColor: _light.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w400),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    dividerTheme: DividerThemeData(color: _light.outline, thickness: 1),
  );

  // =========================
  // ThemeData (Dark)
  // =========================
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: _dark,
    scaffoldBackgroundColor: _dark.background,
    fontFamily: _font,
    textTheme: _textThemeDark(_dark.onBackground),

    appBarTheme: AppBarTheme(
      backgroundColor: _dark.background,
      foregroundColor: _dark.onBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _textThemeDark(_dark.onBackground).titleLarge,
    ),

    cardTheme: CardThemeData(
      color: _dark.surface,
      elevation: 2,
      shadowColor: _dark.shadow,
      shape: _rounded(rMd),
      margin: const EdgeInsets.all(12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _dark.secondary, // brighter on dark
        foregroundColor: _dark.onSecondary,
        minimumSize: const Size.fromHeight(48),
        shape: _rounded(rMd),
        textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _dark.primary,
        foregroundColor: _dark.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: _rounded(rMd),
        textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _dark.secondary,
        textStyle: const TextStyle(
          fontFamily: _font, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cDarkFillAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: cDarkStroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: cDarkStroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: BorderSide(color: _dark.secondary, width: 1.6),
      ),
      hintStyle: TextStyle(color: _dark.onSurfaceVariant),
      labelStyle: TextStyle(color: _dark.onSurface),
    ),

    chipTheme: ChipThemeData(
      labelStyle: TextStyle(color: _dark.onSurface),
      backgroundColor: _dark.surfaceVariant,
      selectedColor: _dark.secondary.withOpacity(.16),
      secondarySelectedColor: _dark.primary.withOpacity(.14),
      shape: _rounded(rSm),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: _dark.surface,
      surfaceTintColor: Colors.transparent,
      shape: _rounded(rLg),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _dark.surface,
      contentTextStyle: TextStyle(color: _dark.onSurface),
      actionTextColor: _dark.secondary,
      behavior: SnackBarBehavior.floating,
      shape: _rounded(rSm),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _dark.surface,
      selectedItemColor: _dark.secondary,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w400),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    dividerTheme: DividerThemeData(color: _dark.outline, thickness: 1),
  );

  // Back-compat text styles (prefer Theme.of(context).textTheme)
  static const TextStyle textBigBlack = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: cNeutral700,
  );
  static const TextStyle textMediumBlack = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: cNeutral700,
  );
  static const TextStyle textSmallGrey = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: cNeutral500,
  );
  static const TextStyle textLink = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    color: cIndigo500,
  );
}
