import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Defines the modern glassmorphic surface system that powers the refreshed
/// dashboard experience. Other features can reuse these helpers to stay
/// visually aligned without duplicating decoration logic.
class ModernSurfaceTheme {
  const ModernSurfaceTheme._();

  // Brand foundations
  static const Color primaryTeal = Color(0xFF1FB9AA);
  static const Color deepTeal = Color(0xFF0D4E47);
  static const Color midnight = Color(0xFF071D1C);
  static const Color softMint = Color(0xFFE9F9F6);
  static const Color accentYellow = Color(0xFFFFD166);
  static const Color accentBlue = Color(0xFF64C7FF);
  static const Color accentCoral = Color(0xFFFF8FA3);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentPurple = Color(0xFFA594F9);

  static ColorScheme _scheme(BuildContext context) =>
      Theme.of(context).colorScheme;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color _blendOnSurface({
    required Color base,
    required Color overlay,
    required double overlayOpacity,
  }) {
    return Color.alphaBlend(overlay.withValues(alpha: overlayOpacity), base);
  }

  /// Page-level gradient background used by dashboards and lifestyle surfaces.
  static LinearGradient backgroundGradient(BuildContext context) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);

    final top = isDark
        ? _blendOnSurface(
            base: midnight,
            overlay: primaryTeal,
            overlayOpacity: 0.28,
          )
        : const Color(0xFF0F5C52);
    final middle = isDark
        ? _blendOnSurface(
            base: scheme.surfaceVariant,
            overlay: primaryTeal,
            overlayOpacity: 0.16,
          )
        : _blendOnSurface(
            base: scheme.surfaceVariant,
            overlay: primaryTeal,
            overlayOpacity: 0.05,
          );
    final bottom = scheme.background;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, middle, bottom],
    );
  }

  /// Primary hero section gradient.
  static LinearGradient heroGradient(BuildContext context, {Color? accent}) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);
    final Color basePrimary = accent ?? primaryTeal;

    final start = isDark
        ? _blendOnSurface(
            base: basePrimary,
            overlay: Colors.white,
            overlayOpacity: 0.08,
          )
        : basePrimary;
    // For the end color, we blend the primary with black to create depth
    final end = isDark
        ? _blendOnSurface(
            base: basePrimary,
            overlay: Colors.black,
            overlayOpacity: 0.25,
          )
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.15), basePrimary);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
    );
  }

  static EdgeInsets screenPadding() {
    return EdgeInsets.only(left: 20.w, right: 20.w, top: 24.h, bottom: 40.h);
  }

  static EdgeInsets heroPadding() => EdgeInsets.all(20.w);

  static double heroSpacing() => 18.h;

  static BoxDecoration heroDecoration(BuildContext context, {Color? accent}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: heroGradient(context, accent: accent),
    );
  }

  static BoxDecoration glassCard(
    BuildContext context, {
    Color? accent,
    bool highlighted = false,
  }) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);
    final Color baseAccent = accent ?? scheme.primary;

    final Color topLayer = _blendOnSurface(
      base: isDark ? scheme.surfaceVariant : Colors.white,
      overlay: baseAccent,
      overlayOpacity: isDark
          ? (highlighted ? 0.22 : 0.16)
          : (highlighted ? 0.08 : 0.05),
    );
    final Color bottomLayer = _blendOnSurface(
      base: scheme.surface,
      overlay: Colors.white,
      overlayOpacity: isDark
          ? (highlighted ? 0.06 : 0.04)
          : (highlighted ? 0.15 : 0.1),
    );

    return BoxDecoration(
      borderRadius: cardRadius(),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [topLayer, bottomLayer],
      ),
      border: Border.all(
        color: baseAccent.withValues(alpha: isDark ? 0.25 : 0.12),
        width: 1.2,
      ),
    );
  }

  /// Specialized decoration for hub grid tiles with category-aware tints.
  static BoxDecoration hubCard(BuildContext context, Color accent) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);

    // Subtle category tint (18% top for more color, 8% bottom for depth)
    final Color blendedTop = _blendOnSurface(
      base: isDark ? scheme.surfaceVariant : Colors.white,
      overlay: accent,
      overlayOpacity: isDark ? 0.32 : 0.18,
    );
    final Color blendedBottom = _blendOnSurface(
      base: scheme.surface,
      overlay: accent,
      overlayOpacity: isDark ? 0.18 : 0.08,
    );

    return BoxDecoration(
      borderRadius: cardRadius(),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [blendedTop, blendedBottom],
      ),
      border: Border.all(
        color: accent.withValues(alpha: isDark ? 0.3 : 0.15),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
    );
  }

  static BoxDecoration tintedCard(BuildContext context, Color accent) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);

    final Color blendedTop = _blendOnSurface(
      base: scheme.surfaceVariant,
      overlay: accent,
      overlayOpacity: isDark ? 0.35 : 0.18,
    );
    final Color blendedBottom = _blendOnSurface(
      base: scheme.surface,
      overlay: accent,
      overlayOpacity: isDark ? 0.22 : 0.1,
    );

    return BoxDecoration(
      borderRadius: cardRadius(),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [blendedTop, blendedBottom],
      ),
      border: Border.all(color: accent.withValues(alpha: isDark ? 0.35 : 0.14)),
    );
  }

  static BoxDecoration pillButton(BuildContext context, Color accent) {
    final isDark = _isDark(context);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          accent.withValues(alpha: isDark ? 0.9 : 0.95),
          accent.withValues(alpha: isDark ? 0.7 : 0.8),
        ],
      ),
    );
  }

  static BoxDecoration iconBadge(BuildContext context, Color accent) {
    final isDark = _isDark(context);

    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: isDark ? 0.85 : 0.95),
          accent.withValues(alpha: isDark ? 0.55 : 0.7),
        ],
      ),
    );
  }

  static BoxDecoration frostedChip(BuildContext context, {Color? baseColor}) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);
    final Color resolvedBase =
        baseColor ??
        (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.white);

    final Color fill = _blendOnSurface(
      base: scheme.surface,
      overlay: resolvedBase,
      overlayOpacity: isDark ? 0.28 : 0.18,
    );

    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: fill,
      border: Border.all(
        color: resolvedBase.withValues(alpha: isDark ? 0.5 : 0.3),
      ),
    );
  }

  /// Returns a high-contrast foreground color for content placed inside
  /// [frostedChip] capsules so that the text/icons remain legible regardless
  /// of the provided [baseColor].
  static Color chipForegroundColor(Color baseColor) {
    final luminance = baseColor.computeLuminance();
    // primaryTeal has luminance around 0.4. We want black/deepTeal for it.
    // Lowering the threshold to ensure teal backgrounds get dark text.
    return luminance > 0.35 ? deepTeal : Colors.white;
  }

  /// Returns a foreground color that contrasts well against tinted cards
  /// produced with [tintedCard] using the provided [accent].
  static Color tintedForegroundColor(
    Color accent, {
    Brightness brightness = Brightness.light,
  }) {
    if (brightness == Brightness.dark) {
      return Colors.white;
    }
    // Simulate the resulting tint by blending the accent over a representative
    // surface color so we can base contrast calculations on the actual
    // background users will see instead of the raw accent hue.
    final Color simulatedTint = _blendOnSurface(
      base: Colors.white,
      overlay: accent,
      overlayOpacity: 0.18,
    );

    final double luminance = simulatedTint.computeLuminance();

    if (luminance > 0.8) {
      return Colors.black87;
    }
    if (luminance > 0.6) {
      return deepTeal;
    }
    return Colors.white;
  }

  static Color tintedMutedColor(
    Color accent, {
    double opacity = 0.75,
    Brightness brightness = Brightness.light,
  }) {
    return tintedForegroundColor(
      accent,
      brightness: brightness,
    ).withValues(alpha: opacity);
  }

  static TextStyle sectionTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 15.sp,
      letterSpacing: -0.5,
    );
  }

  static TextStyle sectionSubtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static EdgeInsets cardPadding() => EdgeInsets.all(20.w);

  static BorderRadius cardRadius() => BorderRadius.circular(24);

  /// Returns a BoxDecoration with a background image for cards.
  /// Use this with a Stack to overlay content on top of the image.
  static BoxDecoration imageCard(
    BuildContext context, {
    required ImageProvider image,
    Color? accent,
    BoxFit fit = BoxFit.cover,
  }) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);
    final Color baseAccent = accent ?? scheme.primary;

    return BoxDecoration(
      borderRadius: cardRadius(),
      image: DecorationImage(
        image: image,
        fit: fit,
        colorFilter: isDark
            ? ColorFilter.mode(
                Colors.black.withValues(alpha: 0.3),
                BlendMode.darken,
              )
            : null,
      ),
      border: Border.all(
        color: baseAccent.withValues(alpha: isDark ? 0.25 : 0.12),
        width: 1.2,
      ),
    );
  }

  /// Returns a BoxDecoration with a background image and gradient overlay.
  /// The gradient overlay helps ensure text readability on top of the image.
  static BoxDecoration imageCardWithOverlay(
    BuildContext context, {
    required ImageProvider image,
    Color? accent,
    BoxFit fit = BoxFit.cover,
  }) {
    final scheme = _scheme(context);
    final isDark = _isDark(context);
    final Color baseAccent = accent ?? scheme.primary;

    return BoxDecoration(
      borderRadius: cardRadius(),
      image: DecorationImage(
        image: image,
        fit: fit,
        colorFilter: ColorFilter.mode(
          isDark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
          BlendMode.srcOver,
        ),
      ),
      border: Border.all(
        color: baseAccent.withValues(alpha: isDark ? 0.25 : 0.12),
        width: 1.2,
      ),
    );
  }
}
