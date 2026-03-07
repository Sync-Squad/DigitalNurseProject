import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/modern_surface_theme.dart';

class FormStepContainer extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final int stepNumber;

  const FormStepContainer({
    super.key,
    required this.title,
    this.description,
    required this.child,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey(stepNumber),
        decoration: ModernSurfaceTheme.glassCard(context, highlighted: true),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ModernSurfaceTheme.deepTeal,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: 8.h),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.7),
                ),
              ),
            ],
            SizedBox(height: 24.h),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
