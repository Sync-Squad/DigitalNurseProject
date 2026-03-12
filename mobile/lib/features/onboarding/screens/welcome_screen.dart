import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      body: Padding(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Column(
          children: [
            // Hero section with gradient decoration
            Container(
              decoration: ModernSurfaceTheme.heroDecoration(context),
              padding: ModernSurfaceTheme.heroPadding(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10.h),
                  // App logo/icon
                  Icon(FIcons.heartPulse, size: 60.h, color: Colors.white),
                  SizedBox(height: 12.h),

                  // App name
                  Text(
                    'app.name'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),

                  // Tagline
                  Text(
                    'app.tagline'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),

                  // Description
                  Text(
                    'app.description'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Features list - individual cards (flexible to fit remaining space)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _FeatureItem(
                      icon: FIcons.pill,
                      title:
                          'onboarding.welcome.features.medicineReminders.title'
                              .tr(),
                      description:
                          'onboarding.welcome.features.medicineReminders.description'
                              .tr(),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: _FeatureItem(
                      icon: FIcons.activity,
                      title: 'onboarding.welcome.features.healthTracking.title'
                          .tr(),
                      description:
                          'onboarding.welcome.features.healthTracking.description'
                              .tr(),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: _FeatureItem(
                      icon: FIcons.users,
                      title:
                          'onboarding.welcome.features.caregiverCoordination.title'
                              .tr(),
                      description:
                          'onboarding.welcome.features.caregiverCoordination.description'
                              .tr(),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: _FeatureItem(
                      icon: FIcons.fileText,
                      title:
                          'onboarding.welcome.features.documentManagement.title'
                              .tr(),
                      description:
                          'onboarding.welcome.features.documentManagement.description'
                              .tr(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Get started button with modern pill style
            Container(
              decoration: ModernSurfaceTheme.pillButton(
                context,
                ModernSurfaceTheme.primaryTeal,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/register'),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 14.h,
                      horizontal: 32.w,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'onboarding.welcome.getStarted'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Login button
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 24.w),
              ),
              child: Text(
                'onboarding.welcome.hasAccount'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ModernSurfaceTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            decoration: ModernSurfaceTheme.iconBadge(
              context,
              ModernSurfaceTheme.primaryTeal,
            ),
            padding: EdgeInsets.all(8.w),
            child: Icon(icon, color: Colors.white, size: 20.h),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    fontSize: 11.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
