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
          childAspectRatio: 1.75, // Matched to Alerts/BP cards height
          children: [
            HubGridTile(
              title: context.tr('hub_medication'),
              subtitle: context.tr('hub_medicationSubtitle'),
              icon: FIcons.pill,
              accentColor: ModernSurfaceTheme.primaryTeal,
              onTap: () => context.push('/medication-hub'),
            ),
            HubGridTile(
              title: context.tr('hub_vitals'),
              subtitle: context.tr('hub_vitalsSubtitle'),
              icon: FIcons.activity,
              accentColor: ModernSurfaceTheme.accentPurple,
              onTap: () => context.push('/vitals-hub'),
            ),
            HubGridTile(
              title: context.tr('hub_lifestyle'),
              subtitle: context.tr('hub_lifestyleSubtitle'),
              icon: FIcons.flame,
              accentColor: ModernSurfaceTheme.accentBlue,
              onTap: () => context.push('/lifestyle-hub'),
            ),
            HubGridTile(
              title: context.tr('hub_documents'),
              subtitle: context.tr('hub_documentsSubtitle'),
              icon: FIcons.fileText,
              accentColor: ModernSurfaceTheme.accentGreen,
              onTap: () => context.push('/documents'),
            ),
          ],
        ),
      ],
    );
  }
}
