import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/medication_provider.dart';
import 'package:digital_nurse/core/utils/timezone_util.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';

class MedicationStatusCard extends StatelessWidget {
  final String elderId;

  const MedicationStatusCard({super.key, required this.elderId});

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final medicines = medicationProvider.medicines;
    final today = TimezoneUtil.nowInPakistan();

    // Count medications by status for today
    int takenCount = 0;
    int missedCount = 0;
    int upcomingCount = 0;

    for (final medicine in medicines) {
      // Check if medicine is active today
      if (medicine.startDate.isAfter(today)) continue;
      if (medicine.endDate != null && medicine.endDate!.isBefore(today))
        continue;

      for (final reminderTime in medicine.reminderTimes) {
        final parts = reminderTime.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final scheduledTime = DateTime(
          today.year,
          today.month,
          today.day,
          hour,
          minute,
        );

        if (scheduledTime.isBefore(TimezoneUtil.nowInPakistan())) {
          // Past time - check if taken or missed
          // For now, we'll count as missed (this should be enhanced with actual intake data)
          missedCount++;
        } else {
          // Future time
          upcomingCount++;
        }
      }
    }

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
                'Medication Status',
                style: ModernSurfaceTheme.sectionTitleStyle(context),
              ),
              TextButton(
                onPressed: () =>
                    context.push('/caregiver/patient/$elderId/medications'),
                child: Text('Manage'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Status summary
          Row(
            children: [
              Expanded(
                child: _StatusMetric(
                  label: 'Taken',
                  count: takenCount,
                  color: AppTheme.getSuccessColor(context),
                  icon: Icons.check_circle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _StatusMetric(
                  label: 'Missed',
                  count: missedCount,
                  color: AppTheme.getErrorColor(context),
                  icon: Icons.cancel,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _StatusMetric(
                  label: 'Upcoming',
                  count: upcomingCount,
                  color: AppTheme.getWarningColor(context),
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Medication timeline for today
          if (medicines.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No medications scheduled',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...medicines
                .take(3)
                .map(
                  (medicine) =>
                      _MedicationItem(medicine: medicine, elderId: elderId),
                ),
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusMetric({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(height: 8.h),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationItem extends StatelessWidget {
  final MedicineModel medicine;
  final String elderId;

  const _MedicationItem({required this.medicine, required this.elderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ModernSurfaceTheme.primaryTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medication,
              size: 20,
              color: ModernSurfaceTheme.primaryTeal,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${medicine.dosage} - ${medicine.reminderTimes.join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
