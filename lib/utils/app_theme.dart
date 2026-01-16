import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Golden shades
  static const Color goldPrimary = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFC5A000);
  static const Color goldLight = Color(0xFFFFEC8B);

  // Black theme
  static const Color blackBackground = Color(0xFF121212);
  static const Color blackSurface = Color(0xFF1E1E1E);

  // White theme
  static const Color whiteBackground = Color(0xFFFAFAFA);
  static const Color whiteSurface = Color(0xFFFFFFFF);
}

class AppTheme {
  static final TextStyle _baseTextStyle = GoogleFonts.amiri();

  static final ThemeData whiteGolden = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.goldPrimary,
    scaffoldBackgroundColor: AppColors.whiteBackground,
    cardColor: AppColors.whiteSurface,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.whiteSurface,
      foregroundColor: AppColors.goldDark,
      elevation: 0,
      titleTextStyle: _baseTextStyle.copyWith(
        color: AppColors.goldDark,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: AppColors.goldDark),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.goldPrimary,
      secondary: AppColors.goldDark,
      surface: AppColors.whiteSurface,
    ),
    textTheme: TextTheme(
      bodyMedium: _baseTextStyle.copyWith(color: Colors.black87, fontSize: 16),
      titleLarge: _baseTextStyle.copyWith(
        color: AppColors.goldDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static final ThemeData blackGolden = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.goldPrimary,
    scaffoldBackgroundColor: AppColors.blackBackground,
    cardColor: AppColors.blackSurface,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.blackSurface,
      foregroundColor: AppColors.goldPrimary,
      elevation: 0,
      titleTextStyle: _baseTextStyle.copyWith(
        color: AppColors.goldPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: AppColors.goldPrimary),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.goldPrimary,
      secondary: AppColors.goldLight,
      surface: AppColors.blackSurface,
    ),
    textTheme: TextTheme(
      bodyMedium: _baseTextStyle.copyWith(color: Colors.white70, fontSize: 16),
      titleLarge: _baseTextStyle.copyWith(
        color: AppColors.goldPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
