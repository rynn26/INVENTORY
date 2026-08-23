import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
    );
  }
}
