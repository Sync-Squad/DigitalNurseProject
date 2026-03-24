import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../dashboard_theme.dart';
import 'package:digital_nurse/features/dashboard/widgets/dashboard_hub_card.dart';

class LifestyleCenterHub extends StatelessWidget {
  const LifestyleCenterHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardHubCard(
      title: 'patient.lifestyle'.tr(),
      icon: Icons.directions_run_rounded,
      accentColor: CaregiverDashboardTheme.accentBlue,
      actions: [
            HubAction(
              label: 'Log Exercise',
              icon: Icons.fitness_center_rounded,
              onTap: () => context.push('/lifestyle/workout/add'),
            ),
            HubAction(
              label: 'Log Diet',
              icon: Icons.restaurant_rounded,
              onTap: () => context.push('/lifestyle/meal/add'),
            ),
            HubAction(
              label: 'View Plans',
              icon: Icons.assignment_rounded,
              onTap: () => context.push('/lifestyle/plans'),
            ),
      ],
    );
  }
}
