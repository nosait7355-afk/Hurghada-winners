import 'package:flutter/material.dart';

class AppThemeConfig {
  AppThemeConfig._();

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;

  // Elevation
  static const double elevationCard = 2.0;
  static const double elevationDialog = 8.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Card shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Button padding
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 12);
}
