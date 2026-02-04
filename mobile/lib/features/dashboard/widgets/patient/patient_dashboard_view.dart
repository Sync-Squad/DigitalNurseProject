import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/providers/auth_provider.dart';
import '../dashboard_theme.dart';
import 'patient_action_shortcuts.dart';
import 'patient_documents_card.dart';
import 'patient_lifestyle_card.dart';
import 'patient_overview_card.dart';
import 'patient_upcoming_medications_card.dart';
import 'patient_vitals_card.dart';
import '../../../../features/ai/widgets/ai_insights_dashboard_widget.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;
    
    final cardSpacing = 18.h;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 24.h,
          bottom: 40.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PatientHero(),
            SizedBox(height: cardSpacing),
            const PatientOverviewCard(),
            SizedBox(height: cardSpacing),
            const PatientActionShortcuts(),
            SizedBox(height: cardSpacing),
            const PatientUpcomingMedicationsCard(),
            SizedBox(height: cardSpacing),
            const PatientVitalsCard(),
            SizedBox(height: cardSpacing),
            const PatientDocumentsCard(),
            SizedBox(height: cardSpacing),
            const PatientLifestyleCard(),
            SizedBox(height: cardSpacing),
            const AIInsightsDashboardWidget(),
          ],
        ),
      ),
    );
  }
}

class _PatientHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;
    
    final user = context.watch<AuthProvider>().currentUser;
    final userName = user?.name ?? 'common.user'.tr();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: CaregiverDashboardTheme.imageCardWithOverlay(
        context,
        image: const AssetImage('assets/Card-2.png'),
        accent: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'patient.welcomeBack'.tr(namedArgs: {'name': userName}),
            style: textTheme.headlineSmall?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            'patient.heroDescription'.tr(),
            style: textTheme.bodyMedium?.copyWith(
                  color: onPrimary.withValues(alpha: 0.85),
                ),
          ),
          // SizedBox(height: 18.h),
          // Wrap(
          //   spacing: 8.w,
          //   runSpacing: 8.h,
          //   children: [
          //     _HeroChip(
          //       label: 'Medication tracking',
          //       icon: Icons.medication_liquid,
          //     ),
          //     _HeroChip(
          //       label: 'Vitals monitoring',
          //       icon: Icons.monitor_heart,
          //     ),
          //     _HeroChip(
          //       label: 'Health insights',
          //       icon: Icons.insights,
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _HeroChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chipForeground =
        CaregiverDashboardTheme.chipForegroundColor(Colors.white);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: CaregiverDashboardTheme.frostedChip(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: chipForeground,
            size: 16,
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: chipForeground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

