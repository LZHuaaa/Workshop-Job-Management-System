import 'package:flutter/material.dart';

class AppColors {
  // Primary Pink Palette
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFF48FB1);
  static const Color lightPink = Color(0xFFFFD1DC);
  static const Color softPink = Color(0xFFF9E1E7);
  static const Color vibrantPink = Color(0xFFFF69B4);
  static const Color deepPink = Color(0xFFE75480);

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF333333);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFE0E0E0);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color primaryBlue = Color(0xFF2196F3);

  // Chart Colors
  static const Color chartPrimary = primaryPink;
  static const Color chartSecondary = accentPink;
  static const Color chartTertiary = lightPink;
  static const Color chartBackground = Color(0xFFF5F5F5);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPink, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [softPink, lightPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
