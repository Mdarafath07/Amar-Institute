import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness:  Brightness.light,
      colorSchemeSeed: AppColors.themeColor,
      scaffoldBackgroundColor:  Colors.white,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.themeColor
      ),
      inputDecorationTheme: _getInputDecorationTheme(),
      filledButtonTheme: _getFilledButtonThemeData(),

    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: AppColors.themeColor,
      scaffoldBackgroundColor: const Color(0xFF0A0E27), // Deep Midnight
      cardColor: const Color(0xFF1A1F3A),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.themeColor,
      ),
      inputDecorationTheme: _getInputDecorationTheme(),
      filledButtonTheme: _getFilledButtonThemeData(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0E27),
        elevation: 0,
      ),
    );
  }
  static InputDecorationTheme _getInputDecorationTheme() {
    return InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.themeColor)),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.themeColor)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.themeColor, width: 2)),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
    );

  }
  static FilledButtonThemeData _getFilledButtonThemeData() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
          fixedSize: Size.fromWidth(double.maxFinite),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: AppColors.themeColor,
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700
          )
      ),
    );
  }
}
