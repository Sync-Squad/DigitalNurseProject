import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_nurse/features/dashboard/widgets/patient/hub_menu_tile.dart';
import 'package:digital_nurse/core/theme/modern_surface_theme.dart';
import 'package:digital_nurse/core/widgets/modern_scaffold.dart';
import 'package:digital_nurse/features/dashboard/widgets/patient/hub_hero_header.dart';

class VitalsHubScreen extends StatelessWidget {
  const VitalsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: Text('Health Hub'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            HubHeroHeader(
              title: 'Health Vitals'.tr(),
              description:
                  'Monitor your vital signs, track trends over time, and keep your healthcare providers informed.'
                      .tr(),
              imagePath: 'assets/images/health.png',
              accentColor: ModernSurfaceTheme.accentPurple,
            ),
            SizedBox(height: 24.h),
            // Grid of Action Tiles
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16.w,
              crossAxisSpacing: 16.w,
              childAspectRatio: 1.35,
              children: [
                HubMenuTile(
                  label: 'Log Vitals',
                  icon: Icons.add_circle_outline_rounded,
                  accentColor: ModernSurfaceTheme.accentPurple,
                  onTap: () => context.push('/vitals/add'),
                ),
                HubMenuTile(
                  label: 'View Vitals',
                  icon: Icons.list_alt_rounded,
                  accentColor: ModernSurfaceTheme.accentPurple,
                  onTap: () => context.push('/health'),
                ),
                HubMenuTile(
                  label: 'Vitals Trends',
                  icon: Icons.trending_up_rounded,
                  accentColor: ModernSurfaceTheme.accentPurple,
                  onTap: () => context.push('/health/trends'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
