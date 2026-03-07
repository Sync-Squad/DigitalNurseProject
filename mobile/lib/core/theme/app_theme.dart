import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../theme/button_styles.dart';
import '../../theme/bottom_navigation_bar_style.dart';

class AppTheme {
  // Teal Color Palette
  static const Color teal = Color(0xFF008080); // Primary teal
  static const Color tealLight = Color(0xFF66B2B2); // Lighter variant
  static const Color tealDark = Color(0xFF006666); // Darker variant
  static const Color tealDarker = Color(
    0xFF004C4C,
  ); // Even darker for dark mode
  static const Color tealLighter = Color(
    0xFFB2D8D8,
  ); // Very light teal for accents

  // Light mode colors
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F8);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F2E);
  static const Color darkSurfaceVariant = Color(0xFF2A3142);

  // Apple Green Color (Secondary)
  // RULE: appleGreen is the standard button color with white text
  static const Color appleGreen = Color(0xFF7FD991); // Apple green
  static const Color buttonTextColor =
      Colors.white; // Standard button text color

  // Blue Color (Tertiary)
  static const Color blueTertiary = Color(0xFF3B82F6); // Blue tertiary

  // Semantic colors that adapt to theme
  static const Color successLight = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);

  // Light theme colors - customize the zinc theme with teal
  static FColors get _lightColors => FThemes.zinc.light.colors.copyWith(
    primary: teal,
    primaryForeground: Colors.white,
    secondary: appleGreen,
    secondaryForeground: Colors.white,
    background: lightBackground,
    foreground: const Color(0xFF1F2937),
    muted: lightSurfaceVariant,
    mutedForeground: const Color(0xFF6B7280),
    destructive: errorLight,
    destructiveForeground: Colors.white,
    border: const Color(0xFFE5E7EB),
  );

  // Dark theme colors - customize the zinc theme with teal
  static FColors get _darkColors => FThemes.zinc.dark.colors.copyWith(
    primary: tealLight,
    primaryForeground: Colors.white,
    secondary: appleGreen,
    secondaryForeground: Colors.white,
    background: darkBackground,
    foreground: const Color(0xFFE5E7EB),
    muted: darkSurfaceVariant,
    mutedForeground: const Color(0xFF9CA3AF),
    destructive: errorDark,
    destructiveForeground: darkBackground,
    border: const Color(0xFF374151),
  );

  // Light theme - use existing zinc theme and customize colors
  static FThemeData get lightTheme {
    final colors = _lightColors;
    final typography = FThemes.zinc.light.typography;
    final fStyle = FThemes.zinc.light.style;

    return FThemes.zinc.light.copyWith(
      colors: colors,
      buttonStyles: buttonStyles(
        colors: colors,
        typography: typography,
        style: fStyle,
      ),
      bottomNavigationBarStyle: bottomNavigationBarStyle(
        colors: colors,
        typography: typography,
        style: fStyle,
      ),
      lineCalendarStyle: (_) => FLineCalendarStyle.inherit(
        colors: colors.copyWith(primary: appleGreen),
        typography: typography,
        style: fStyle,
      ),
    );
  }

  // Dark theme - use existing zinc theme and customize colors
  static FThemeData get darkTheme {
    final colors = _darkColors;
    final typography = FThemes.zinc.dark.typography;
    final fStyle = FThemes.zinc.dark.style;

    return FThemes.zinc.dark.copyWith(
      colors: colors,
      buttonStyles: buttonStyles(
        colors: colors,
        typography: typography,
        style: fStyle,
      ),
      bottomNavigationBarStyle: bottomNavigationBarStyle(
        colors: colors,
        typography: typography,
        style: fStyle,
      ),
      lineCalendarStyle: (_) => FLineCalendarStyle.inherit(
        colors: colors.copyWith(primary: appleGreen),
        typography: typography,
        style: fStyle,
      ),
    );
  }

  // Helper methods for semantic colors based on theme
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? successDark
        : successLight;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? errorDark
        : errorLight;
  }

  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? warningDark
        : warningLight;
  }

  // Document type colors that adapt to theme
  static Color getDocumentColor(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type.toLowerCase()) {
      case 'prescription':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
      case 'labreport':
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF10B981);
      case 'xray':
      case 'scan':
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
      case 'discharge':
        return isDark ? const Color(0xFFFB923C) : const Color(0xFFF59E0B);
      case 'insurance':
        return isDark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);
      default:
        return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    }
  }
}
