import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/models/vital_measurement_model.dart';
import '../../../core/extensions/vital_type_extensions.dart';
import '../../../core/extensions/vital_status_extensions.dart';
import '../../../core/theme/modern_surface_theme.dart';

class VitalsSummaryCard extends StatelessWidget {
  final String elderId;

  const VitalsSummaryCard({super.key, required this.elderId});

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final vitals = healthProvider.vitals;

    // Get latest vitals by type
    final latestVitals = <VitalType, VitalMeasurementModel>{};
    for (final vital in vitals) {
      if (!latestVitals.containsKey(vital.type) ||
          latestVitals[vital.type]!.timestamp.isBefore(vital.timestamp)) {
        latestVitals[vital.type] = vital;
      }
    }

    // Priority vitals to show
    final priorityTypes = [
      VitalType.bloodPressure,
      VitalType.heartRate,
      VitalType.bloodSugar,
    ];

    final displayedVitals = priorityTypes
        .where((type) => latestVitals.containsKey(type))
        .map((type) => latestVitals[type]!)
        .toList();

    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vitals Summary',
                style: ModernSurfaceTheme.sectionTitleStyle(context),
              ),
              TextButton(
                onPressed: () => context.push('/health'),
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (displayedVitals.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No vitals recorded yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...displayedVitals.map((vital) => _VitalItem(vital: vital)),
        ],
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  final VitalMeasurementModel vital;

  const _VitalItem({required this.vital});

  @override
  Widget build(BuildContext context) {
    final status = vital.getHealthStatus();
    final isAbnormal = vital.isAbnormal();

    final statusColor = status.getStatusColor(context);
    final statusIcon = status.getStatusIcon();
    final statusText = vital.getStatusMessage(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: isAbnormal
          ? ModernSurfaceTheme.tintedCard(context, statusColor)
          : ModernSurfaceTheme.glassCard(context),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: ModernSurfaceTheme.iconBadge(context, statusColor),
            child: Icon(statusIcon, size: 20, color: Colors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vital.type.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isAbnormal
                        ? ModernSurfaceTheme.tintedForegroundColor(statusColor)
                        : null,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${vital.value} ${vital.type.unit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isAbnormal
                        ? ModernSurfaceTheme.tintedMutedColor(statusColor)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: ModernSurfaceTheme.frostedChip(
              context,
              baseColor: isAbnormal ? Colors.white : statusColor,
            ),
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isAbnormal ? statusColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
