import 'package:digital_nurse/core/extensions/vital_type_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/vital_measurement_model.dart';
import '../../../../core/extensions/vital_status_extensions.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../dashboard_theme.dart';
import 'expandable_patient_card.dart';

class PatientVitalsCard extends StatelessWidget {
  const PatientVitalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final healthProvider = context.watch<HealthProvider>();
    final recentVitals = healthProvider.vitals.take(5).toList();
    final abnormalVitals = healthProvider.vitals
        .where((vital) => vital.isAbnormal())
        .take(5)
        .toList();
    final brightness = Theme.of(context).brightness;

    return ExpandablePatientCard(
      icon: Icons.monitor_heart_outlined,
      title: 'patient.yourVitals'.tr(),
      subtitle: abnormalVitals.isNotEmpty
          ? 'patient.vitalsSubtitleAbnormal'.tr()
          : 'patient.vitalsSubtitleNormal'.tr(),
      count: '${recentVitals.length}',
      accentColor: CaregiverDashboardTheme.accentCoral,
      routeForViewDetails: '/health',
      expandedChild: recentVitals.isEmpty
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: CaregiverDashboardTheme.tintedCard(
                context,
                CaregiverDashboardTheme.primaryTeal,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: CaregiverDashboardTheme.iconBadge(
                      context,
                      CaregiverDashboardTheme.primaryTeal,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'patient.noVitalsRecorded'.tr(),
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CaregiverDashboardTheme.tintedForegroundColor(
                          CaregiverDashboardTheme.primaryTeal,
                          brightness: brightness,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...recentVitals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final vital = entry.value;
                  final isAbnormal = vital.isAbnormal();
                  final status = vital.getHealthStatus();
                  final statusColor = status == VitalHealthStatus.normal
                      ? CaregiverDashboardTheme.primaryTeal
                      : status.getStatusColor(context);
                  final isLast = index == recentVitals.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
                    child: _VitalRow(
                      vital: vital,
                      accent: isAbnormal
                          ? statusColor
                          : CaregiverDashboardTheme.primaryTeal,
                      onTap: () => context.push('/health'),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}

class _VitalRow extends StatelessWidget {
  final VitalMeasurementModel vital;
  final Color accent;
  final VoidCallback onTap;

  const _VitalRow({
    required this.vital,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final brightness = Theme.of(context).brightness;
    final onTint = CaregiverDashboardTheme.tintedForegroundColor(
      accent,
      brightness: brightness,
    );
    final onTintMuted = CaregiverDashboardTheme.tintedMutedColor(
      accent,
      brightness: brightness,
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: CaregiverDashboardTheme.tintedCard(context, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: CaregiverDashboardTheme.iconBadge(context, accent),
                child: const Icon(
                  Icons.monitor_heart,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vital.type.displayName,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onTint,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${vital.value} ${vital.type.unit}',
                      style: context.theme.typography.xs.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onTint,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: context.theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text('patient.review'.tr()),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            DateFormat('MMM d, h:mm a').format(vital.timestamp),
            style: context.theme.typography.xs.copyWith(color: onTintMuted),
          ),
        ],
      ),
    );
  }
}
