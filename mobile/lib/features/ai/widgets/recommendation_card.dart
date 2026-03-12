import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/modern_surface_theme.dart';

class RecommendationCard extends StatelessWidget {
  final String recommendation;
  final String? category;
  final VoidCallback? onAction;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.category,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: ModernSurfaceTheme.iconBadge(
              context,
              Theme.of(context).colorScheme.primary,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      category!.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}
