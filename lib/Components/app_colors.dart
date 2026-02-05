import 'package:flutter/material.dart';

class AppColors {
  // Light Blue Theme Color Palette
  static const Color primaryColor = Color(0xFF87CEEB); // Sky Blue - main accent
  static const Color secondaryColor = Color(
    0xFFF0F8FF,
  ); // Alice Blue - light background
  static const Color backgroundColor = Color(
    0xFFE6F3FF,
  ); // Very light blue background
  static const Color textColor = Color(0xFF2C3E50); // Dark blue-gray for text
  static const Color hintColor = Color(0xFF95A5A6); // Light gray for hints
  static const Color errorColor = Color(0xFFE74C3C); // Soft red for errors
  static const Color accentColor = Color(
    0xFF4A90E2,
  ); // Bright blue for highlights
  static const Color surfaceColor = Color(
    0xFFFFFFFF,
  ); // White for cards/surfaces

  // Dark Theme Color Palette
  static const Color darkPrimaryColor = Color(
    0xFF5BA3D9,
  ); // Softer blue for dark mode
  static const Color darkSecondaryColor = Color(0xFF1E2937); // Dark blue-gray
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Very dark blue
  static const Color darkTextColor = Color(0xFFE2E8F0); // Light gray for text
  static const Color darkHintColor = Color(0xFF64748B); // Medium gray for hints
  static const Color darkErrorColor = Color(
    0xFFF87171,
  ); // Lighter red for dark mode
  static const Color darkAccentColor = Color(
    0xFF60A5FA,
  ); // Bright blue for dark mode
  static const Color darkSurfaceColor = Color(0xFF1E293B); // Dark surface color

  // Emotion Colors (same for both themes)
  static const Color emotionJoy = Color(0xFF10B981);
  static const Color emotionSadness = Color(0xFF6B7280);
  static const Color emotionAnger = Color(0xFFEF4444);
  static const Color emotionFear = Color(0xFF8B5CF6);
  static const Color emotionLove = Color(0xFFEC4899);
  static const Color emotionSurprise = Color(0xFFF59E0B);
  static const Color emotionNeutral = Color(0xFF9CA3AF);
  static const Color emotionDisgust = Color(0xFF84CC16);

  /// Get color for emotion
  static Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return emotionJoy;
      case 'sadness':
        return emotionSadness;
      case 'anger':
        return emotionAnger;
      case 'fear':
        return emotionFear;
      case 'love':
        return emotionLove;
      case 'surprise':
        return emotionSurprise;
      case 'disgust':
        return emotionDisgust;
      default:
        return emotionNeutral;
    }
  }
}

/// Theme-aware color helper
class ThemeColors {
  final bool isDark;

  ThemeColors({required this.isDark});

  Color get primaryColor =>
      isDark ? AppColors.darkPrimaryColor : AppColors.primaryColor;
  Color get secondaryColor =>
      isDark ? AppColors.darkSecondaryColor : AppColors.secondaryColor;
  Color get backgroundColor =>
      isDark ? AppColors.darkBackgroundColor : AppColors.backgroundColor;
  Color get textColor => isDark ? AppColors.darkTextColor : AppColors.textColor;
  Color get hintColor => isDark ? AppColors.darkHintColor : AppColors.hintColor;
  Color get errorColor =>
      isDark ? AppColors.darkErrorColor : AppColors.errorColor;
  Color get accentColor =>
      isDark ? AppColors.darkAccentColor : AppColors.accentColor;
  Color get surfaceColor =>
      isDark ? AppColors.darkSurfaceColor : AppColors.surfaceColor;

  /// Get colors from BuildContext
  static ThemeColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ThemeColors(isDark: brightness == Brightness.dark);
  }
}
