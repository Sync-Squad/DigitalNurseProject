import 'package:flutter/material.dart';

/// Utility functions for generating professional avatar colors
class AvatarUtil {
  /// Professional color palette for avatars
  /// These colors are muted, professional, and suitable for healthcare contexts
  static const List<Color> _professionalColors = [
    Color(0xFF1FB9AA), // Primary Teal
    Color(0xFF0D4E47), // Deep Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFF7C3AED), // Violet
    Color(0xFF059669), // Green
    Color(0xFF64748B), // Slate
    Color(0xFF475569), // Dark Slate
    Color(0xFFCA8A04), // Amber (muted)
    Color(0xFFEA580C), // Orange (muted)
    Color(0xFFDC2626), // Red (muted)
  ];

  /// Generates a consistent avatar color based on a seed (user ID or name)
  ///
  /// Uses a hash of the seed to deterministically select a color from the
  /// professional color palette. The same seed will always return the same color.
  ///
  /// [seed] - A unique identifier (e.g., user ID, name, email)
  /// Returns a Color from the professional palette
  static Color getAvatarColor(String seed) {
    // Generate a hash from the seed
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Use absolute value and modulo to select a color
    final index = hash.abs() % _professionalColors.length;
    return _professionalColors[index];
  }

  /// @deprecated Use ProfessionalAvatar widget instead
  /// This method is kept for backward compatibility but should not be used in new code.
  @Deprecated('Use ProfessionalAvatar widget instead of generating avatar URLs')
  static String getRandomAvatarUrl(String seed) {
    // This method is deprecated - avatars should use initials-based ProfessionalAvatar widget
    // Keeping for backward compatibility during migration
    final encodedSeed = Uri.encodeComponent(seed);
    return 'https://api.dicebear.com/7.x/avataaars/png?seed=$encodedSeed';
  }
}
