import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';

import '../../../../core/theme/modern_surface_theme.dart';
import 'hub_grid_tile.dart';

class DashboardHubGrid extends StatelessWidget {
  const DashboardHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.35, // Shorter cards to match top-level cards
          children: [
            HubGridTile(
              title: 'Medication',
              subtitle: 'Upcoming & Overdue',
              icon: FIcons.pill,
              accentColor: ModernSurfaceTheme.primaryTeal,
              onTap: () => context.push('/medication-hub'),
            ),
            HubGridTile(
              title: 'Health Vitals',
              subtitle: 'Trends & Logging',
              icon: FIcons.activity,
              accentColor: ModernSurfaceTheme.accentCoral,
              onTap: () => context.push('/vitals-hub'),
            ),
            HubGridTile(
              title: 'Lifestyle',
              subtitle: 'Exercise & Diet',
              icon: FIcons.flame,
              accentColor: ModernSurfaceTheme.accentBlue,
              onTap: () => context.push('/lifestyle-hub'),
            ),
            HubGridTile(
              title: 'Documents',
              subtitle: 'Reports & Records',
              icon: FIcons.fileText,
              accentColor: ModernSurfaceTheme.primaryTeal,
              onTap: () => context.push('/documents'),
            ),
          ],
        ),
      ],
    );
  }
}
