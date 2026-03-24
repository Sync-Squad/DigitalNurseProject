import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../dashboard_theme.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/models/vital_measurement_model.dart';
import '../../../../core/extensions/vital_status_extensions.dart';

class AlertsBPGrid extends StatelessWidget {
  const AlertsBPGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final abnormalVitals = healthProvider.vitals
        .where((vital) => vital.isAbnormal())
        .toList();

    // Specifically find the latest blood pressure measurement
    final latestBP = healthProvider.vitals.isEmpty
        ? null
        : healthProvider.vitals.firstWhere(
            (v) => v.type == VitalType.bloodPressure,
            orElse: () => healthProvider.vitals.first,
          );

    final actualLatestBP = latestBP?.type == VitalType.bloodPressure
        ? latestBP
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _AlertsCard(alertCount: abnormalVitals.length)),
          SizedBox(width: 12.w),
          Expanded(child: _BloodPressureCard(latestVital: actualLatestBP)),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final int alertCount;
  const _AlertsCard({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alertCount > 0 ? () => context.push('/health/abnormal') : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFFF5E6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB84D).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB84D), size: 18),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'patient.alertsTitle'.tr(),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          fontSize: 12.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  alertCount > 0
                      ? 'patient.vitalsNeedCheck'.tr(namedArgs: {'count': alertCount.toString()})
                      : 'patient.allVitalsGood'.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BloodPressureCard extends StatelessWidget {
  final VitalMeasurementModel? latestVital;
  const _BloodPressureCard({this.latestVital});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasData = latestVital != null;
    
    String systolicStr = '--';
    String diastolicStr = '--';
    
    if (hasData) {
      final parts = latestVital!.value.split('/');
      systolicStr = parts[0];
      if (parts.length > 1) diastolicStr = parts[1];
    }

    final status = hasData ? latestVital!.getStatusLabel(context) : 'patient.noRecordsYet'.tr();
    final statusColor = hasData ? latestVital!.getHealthStatus().getStatusColor(context) : const Color(0xFF999999);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasData ? () => context.push('/health') : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: CaregiverDashboardTheme.accentCoral.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.favorite, color: CaregiverDashboardTheme.accentCoral, size: 18),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'patient.bloodPressureTitle'.tr(),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '$systolicStr / $diastolicStr',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasData ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC),
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                status,
                style: textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
