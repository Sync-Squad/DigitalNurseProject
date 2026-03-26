import 'package:digital_nurse/core/extensions/vital_type_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/health_provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../dashboard_theme.dart';

class CaregiverOverviewCard extends StatelessWidget {
  const CaregiverOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final healthProvider = context.watch<HealthProvider>();

    final adherencePercentage = medicationProvider.adherencePercentage
        .clamp(0, 100)
        .toDouble();

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
        label: 'Adherence',
        value: '${adherencePercentage.toStringAsFixed(0)}%',
        description: 'On-time doses across the last 7 days.',
        icon: Icons.monitor_heart,
        accent: adherenceAccent,
      ),
      _OverviewMetric(
        label: 'Streak',
        value: '${medicationProvider.adherenceStreak} days',
        description: 'Continuous adherence streak.',
        icon: Icons.local_fire_department,
        accent: CaregiverDashboardTheme.accentYellow,
      ),
      _OverviewMetric(
        label: 'Alerts',
        value: '${abnormalVitals.length}',
        description: 'Abnormal vitals needing attention.',
        icon: Icons.warning_amber_rounded,
        accent: alertsAccent,
        onTap: () => context.push('/health/abnormal'),
      ),
      if (latestVital != null)
        _OverviewMetric(
          label: 'Last vital',
          value:
              '${latestVital.type.displayName}: ${latestVital.value} ${latestVital.type.unit}',
          description: 'Most recent recording.',
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

        return Container(
          padding: CaregiverDashboardTheme.cardPadding(),
          decoration: CaregiverDashboardTheme.glassCard(
            context,
            highlighted: true,
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
                          'Care overview',
                          style: CaregiverDashboardTheme.sectionTitleStyle(
                            context,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Real-time snapshot of adherence, alerts, and vitals for your recipients.',
                          style: CaregiverDashboardTheme.sectionSubtitleStyle(
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
  final VoidCallback? onTap;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.accent,
    this.maxLines = 1,
    this.onTap,
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
    final content = AnimatedContainer(
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

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      );
    }

    return content;
  }
}
