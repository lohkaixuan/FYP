import 'package:flutter/material.dart';

class AppTextStyles {
  static const TextStyle small  = TextStyle(fontSize: 8, fontWeight: FontWeight.w400);
  static const TextStyle medium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle large  = TextStyle(fontSize: 20, fontWeight: FontWeight.w800);
}

class AppTheme {
  // 🎯 Brand colors (blue & white only)
  static const Color kBlue = Color(0xFF1565C0); // blue-700-ish
  static const Color kWhite = Colors.white;
  static const Color kText  = Colors.black87;
  static const Color kTextFaded = Colors.black54;

  // 🔹 Common Rounded Shape
  static final RoundedRectangleBorder commonRoundedShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  // 🔹 Button TextStyle
  static const TextStyle buttonTextStyle = AppTextStyles.small;

  // 🔹 Shared Button Styles
  static ButtonStyle elevatedButtonStyle(Color bgColor, Color fgColor) =>
      ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        shape: commonRoundedShape,
        textStyle: buttonTextStyle,
      );

  static ButtonStyle outlinedButtonStyle(Color color) =>
      OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.2),
        shape: commonRoundedShape,
        textStyle: buttonTextStyle,
      );

  static ButtonStyle textButtonStyle(Color color) =>
      TextButton.styleFrom(
        foregroundColor: color,
        textStyle: buttonTextStyle,
      );

  // 🔹 Bottom Nav Label Style
  static TextStyle bottomNavLabelStyle(Color color) =>
      AppTextStyles.small.copyWith(color: color);

  /// 🌈 Single look for everything (light & dark the same)
  static final ThemeData lightTheme = _buildBlueWhiteTheme();
  static final ThemeData darkTheme  = _buildBlueWhiteTheme(); // same as light

  static ThemeData _buildBlueWhiteTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,                 // force light-look
      primaryColor: kBlue,
      scaffoldBackgroundColor: kWhite,

      appBarTheme: const AppBarTheme(
        backgroundColor: kWhite,                    // white appbar
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: kBlue),     // blue icons
        titleTextStyle: TextStyle(                  // blue title
          fontSize: 20, fontWeight: FontWeight.w800, color: kBlue),
      ),

      iconTheme: const IconThemeData(color: kBlue),

      textTheme: TextTheme(
        bodyMedium: AppTextStyles.small.copyWith(color: kTextFaded),
        bodyLarge : AppTextStyles.medium.copyWith(color: kText),
        titleLarge: AppTextStyles.large.copyWith(color: kBlue),
        labelLarge: AppTextStyles.small.copyWith(color: kText),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: kWhite,
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: bottomNavLabelStyle(kBlue),
        unselectedLabelStyle: bottomNavLabelStyle(Colors.grey),
        type: BottomNavigationBarType.fixed,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: elevatedButtonStyle(kBlue, kWhite),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlinedButtonStyle(kBlue),
      ),
      textButtonTheme: TextButtonThemeData(
        style: textButtonStyle(kBlue),
      ),

      colorScheme: const ColorScheme.light(
        primary: kBlue,
        onPrimary: kWhite,
        surface: kWhite,
        onSurface: kText,
      ),
    );
  }
}
