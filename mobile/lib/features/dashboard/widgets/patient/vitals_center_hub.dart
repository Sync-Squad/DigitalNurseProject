import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../dashboard_theme.dart';
import 'package:digital_nurse/features/dashboard/widgets/dashboard_hub_card.dart';

class VitalsCenterHub extends StatelessWidget {
  const VitalsCenterHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardHubCard(
      title: 'vitals.title'.tr(),
      icon: Icons.favorite_rounded,
      accentColor: CaregiverDashboardTheme.accentCoral,
      actions: [
            HubAction(
              label: 'Log Vitals',
              icon: Icons.add_circle_outline_rounded,
              onTap: () => context.push('/vitals/add'),
            ),
            HubAction(
              label: 'View Vitals',
              icon: Icons.list_alt_rounded,
              onTap: () => context.push('/health'),
            ),
        HubAction(
          label: 'Vitals Trends',
          icon: Icons.trending_up_rounded,
          onTap: () => context.push('/health/trends'),
        ),
      ],
    );
  }
}
