import 'package:digital_nurse/core/extensions/vital_type_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/providers/health_provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../dashboard_theme.dart';
import 'adherence_streak_card.dart';

class PatientOverviewCard extends StatelessWidget {
  const PatientOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final medicationProvider = context.watch<MedicationProvider>();
    final healthProvider = context.watch<HealthProvider>();

    final adherencePercentage = medicationProvider.adherencePercentage
        .clamp(0, 100)
        .toDouble();
    final adherenceStreak = medicationProvider.adherenceStreak;

    final abnormalVitals = healthProvider.vitals
        .where((vital) => vital.isAbnormal())
        .toList();
    final latestVital = healthProvider.vitals.isNotEmpty
        ? healthProvider.vitals.first
        : null;

    final adherenceAccent = adherencePercentage >= 90
        ? CaregiverDashboardTheme.primaryTeal
        : adherencePercentage >= 75
        ? CaregiverDashboardTheme.accentYellow
        : CaregiverDashboardTheme.accentCoral;
    final alertsAccent = abnormalVitals.isEmpty
        ? CaregiverDashboardTheme.primaryTeal
        : const Color(0xFFFFB84D); // Orange-yellowish color

    final cards = <_OverviewMetric>[
      _OverviewMetric(
        label: 'patient.adherence'.tr(),
        value: '${adherencePercentage.toStringAsFixed(0)}%',
        description: 'patient.adherenceDescription'.tr(),
        icon: Icons.monitor_heart,
        accent: adherenceAccent,
      ),
      // _OverviewMetric(
      //   label: 'Streak',
      //   value: '$adherenceStreak days',
      //   description: 'Continuous adherence streak.',
      //   icon: Icons.local_fire_department,
      //   accent: CaregiverDashboardTheme.accentYellow,
      // ),
      // _OverviewMetric(
      //   label: 'Upcoming doses',
      //   value: '$upcomingToday today',
      //   description: 'Scheduled after right now.',
      //   icon: Icons.schedule,
      //   accent: CaregiverDashboardTheme.accentBlue,
      // ),
      _OverviewMetric(
        label: 'patient.alerts'.tr(),
        value: '${abnormalVitals.length}',
        description: 'patient.alertsDescription'.tr(),
        icon: Icons.warning_amber_rounded,
        accent: alertsAccent,
      ),
      if (latestVital != null)
        _OverviewMetric(
          label: 'patient.lastVital'.tr(),
          value:
              '${latestVital.type.displayName}: ${latestVital.value} ${latestVital.type.unit}',
          description: 'patient.lastVitalDescription'.tr(),
          icon: Icons.favorite,
          accent: CaregiverDashboardTheme.primaryTeal,
          maxLines: 2,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final crossAxisCount = isWide ? 2 : 1;
        final crossAxisSpacing = 12.w;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adherence Streak Card - Prominent display
            AdherenceStreakCard(
              streakDays: adherenceStreak,
              adherencePercentage: adherencePercentage,
            ),
            SizedBox(height: 18.h),
            // Overview metrics card
            Container(
              padding: CaregiverDashboardTheme.cardPadding(),
              decoration: CaregiverDashboardTheme.imageCardWithOverlay(
                context,
                //image: const AssetImage('assets/Card-2.png'),
                image: const AssetImage('assets/images/cardbackground1.jpeg'),
                accent: CaregiverDashboardTheme.primaryTeal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: CaregiverDashboardTheme.iconBadge(
                          context,
                          CaregiverDashboardTheme.primaryTeal,
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'patient.healthOverview'.tr(),
                              style: CaregiverDashboardTheme.sectionTitleStyle(
                                context,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'patient.overviewDescription'.tr(),
                              style:
                                  CaregiverDashboardTheme.sectionSubtitleStyle(
                                    context,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Wrap(
                    spacing: crossAxisSpacing,
                    runSpacing: 16.h,
                    children: cards
                        .map(
                          (metric) => SizedBox(
                            width: crossAxisCount == 1
                                ? constraints.maxWidth
                                : (constraints.maxWidth - crossAxisSpacing) /
                                      crossAxisCount,
                            child: metric,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final Color accent;
  final int maxLines;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.accent,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.theme.typography;
    final brightness = Theme.of(context).brightness;
    final contentColor = CaregiverDashboardTheme.tintedForegroundColor(
      accent,
      brightness: brightness,
    );
    final mutedContent = CaregiverDashboardTheme.tintedMutedColor(
      accent,
      brightness: brightness,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: CaregiverDashboardTheme.tintedCard(context, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: CaregiverDashboardTheme.iconBadge(context, accent),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.sm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: contentColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      label,
                      style: textTheme.xs.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mutedContent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(description, style: textTheme.xs.copyWith(color: mutedContent)),
        ],
      ),
    );
  }
}
