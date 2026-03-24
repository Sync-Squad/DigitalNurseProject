import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import '../../../../core/theme/modern_surface_theme.dart';

class HubGridTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const HubGridTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: ModernSurfaceTheme.glassCard(
            context,
            accent: accentColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Modern Icon Badge
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration:
                        ModernSurfaceTheme.iconBadge(context, accentColor),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1E1E),
                        fontSize: 13.sp,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2, // Allow 2 lines for longer titles in grid
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                    fontSize: 10.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
