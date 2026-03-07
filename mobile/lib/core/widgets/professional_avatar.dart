import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/avatar_util.dart';

/// A professional avatar widget that displays user initials with a colored background.
/// Supports optional network images for real user photos, with fallback to initials.
class ProfessionalAvatar extends StatelessWidget {
  /// The user's name (used for generating initials)
  final String name;

  /// Optional user ID for consistent color generation
  final String? userId;

  /// Optional URL to a real user photo from the backend
  final String? avatarUrl;

  /// Size of the avatar (diameter)
  final double size;

  /// Optional custom background color (overrides generated color)
  final Color? backgroundColor;

  /// Optional custom text color (defaults to white)
  final Color? textColor;

  const ProfessionalAvatar({
    super.key,
    required this.name,
    this.userId,
    this.avatarUrl,
    this.size = 48.0,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final seed = userId ?? name;
    final bgColor = backgroundColor ?? AvatarUtil.getAvatarColor(seed);
    final txtColor = textColor ?? Colors.white;
    final initials = _getInitials(name);

    // If avatarUrl is provided and not empty, try to load it
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Container(
          width: size,
          height: size,
          color: bgColor,
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                _buildInitialsPlaceholder(context, initials, bgColor, txtColor),
            errorWidget: (context, url, error) {
              debugPrint('Avatar image error: $error for URL: $url');
              return _buildInitialsPlaceholder(
                context,
                initials,
                bgColor,
                txtColor,
              );
            },
          ),
        ),
      );
    }

    // Default to initials-based avatar
    return _buildInitialsPlaceholder(context, initials, bgColor, txtColor);
  }

  Widget _buildInitialsPlaceholder(
    BuildContext context,
    String initials,
    Color bgColor,
    Color txtColor,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: txtColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Extracts initials from a name (handles multiple words)
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      // Single name - use first two letters if available, otherwise first letter
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0][0].toUpperCase();
    } else {
      // Multiple names - use first letter of first and last name
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
  }
}
