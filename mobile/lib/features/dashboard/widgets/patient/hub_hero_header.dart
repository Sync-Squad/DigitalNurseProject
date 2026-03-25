import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/modern_surface_theme.dart';

class HubHeroHeader extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final Color? accentColor;
  final double? imageWidth;
  final Widget? child;

  const HubHeroHeader({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.accentColor,
    this.imageWidth,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final finalImageWidth = imageWidth ?? 140.w;

    return Container(
      width: double.infinity,
      decoration: ModernSurfaceTheme.heroDecoration(context, accent: accentColor),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Right side: Image
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: finalImageWidth,
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
          ),
          // Left side: Content
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, finalImageWidth + 8.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22.sp,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: onPrimary.withValues(alpha: 0.85),
                    fontSize: 13.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (child != null) ...[
                  SizedBox(height: 16.h),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
