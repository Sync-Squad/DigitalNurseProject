import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_nurse/features/dashboard/widgets/patient/hub_menu_tile.dart';
import 'package:digital_nurse/core/theme/modern_surface_theme.dart';
import 'package:digital_nurse/core/widgets/modern_scaffold.dart';
import 'package:digital_nurse/features/dashboard/widgets/patient/hub_hero_header.dart';

class LifestyleHubScreen extends StatelessWidget {
  const LifestyleHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: Text('Lifestyle Hub'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            HubHeroHeader(
              title: 'Lifestyle Hub'.tr(),
              description:
                  'Track your diet, log exercises, and stay committed to your wellness journey.'
                      .tr(),
              imagePath: 'assets/images/health.png',
            ),
            SizedBox(height: 24.h),
            // Grid of Action Tiles
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16.w,
              crossAxisSpacing: 16.w,
              childAspectRatio: 1.1,
              children: [
                HubMenuTile(
                  label: 'Log Exercise',
                  icon: Icons.fitness_center_rounded,
                  accentColor: ModernSurfaceTheme.accentBlue,
                  onTap: () => context.push('/lifestyle/workout/add'),
                ),
                HubMenuTile(
                  label: 'Log Diet',
                  icon: Icons.restaurant_rounded,
                  accentColor: ModernSurfaceTheme.accentCoral,
                  onTap: () => context.push('/lifestyle/meal/add'),
                ),
                HubMenuTile(
                  label: 'View Plans',
                  icon: Icons.assignment_rounded,
                  accentColor: ModernSurfaceTheme.primaryTeal,
                  onTap: () => context.push('/lifestyle/plans'),
                ),
                HubMenuTile(
                  label: 'Health Trends',
                  icon: Icons.trending_up_rounded,
                  accentColor: ModernSurfaceTheme.primaryTeal,
                  onTap: () => context.push('/lifestyle/trends'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
