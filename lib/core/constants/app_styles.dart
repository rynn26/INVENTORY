import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Border Radius Tokens
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusPill = 24.0;
  static const double radiusModal = 24.0;

  // Standard Card Box Decoration
  static BoxDecoration cardDecoration({
    Color backgroundColor = AppColors.surface,
    BorderRadius? borderRadius,
    Color borderColor = AppColors.border,
    double borderWidth = 1.2,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusCard),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Standard Primary Button Style
  static ButtonStyle primaryButtonStyle({
    double height = 48.0,
    double radius = radiusMedium,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  // Standard Outlined Button Style
  static ButtonStyle outlinedButtonStyle({
    double height = 48.0,
    double radius = radiusMedium,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
