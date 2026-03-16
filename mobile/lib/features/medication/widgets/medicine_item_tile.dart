import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_util.dart';
import '../../../core/theme/modern_surface_theme.dart';

class MedicineItemTile extends StatelessWidget {
  final MedicineModel medicine;
  final String reminderTime;
  final IntakeStatus status;
  final DateTime selectedDate;
  final VoidCallback? onStatusChanged;

  const MedicineItemTile({
    super.key,
    required this.medicine,
    required this.reminderTime,
    required this.status,
    required this.selectedDate,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.read<MedicationProvider>();
    final timeDisplay = medicationProvider.getTimeOfDayString(reminderTime);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = colorScheme.surfaceVariant.withValues(
      alpha: isDark ? 0.55 : 0.35,
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: tileColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                // Pass the selected date and reminder time as query parameters
                final dateStr =
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                final timeStr = Uri.encodeComponent(reminderTime);
                context.push(
                  '/medicine/${medicine.id}?selectedDate=$dateStr&reminderTime=$timeStr',
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${medicine.dosage} • $timeDisplay',
                            style: textTheme.bodySmall?.copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _PriorityBadge(priority: medicine.priority),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _buildStatusButton(context),
        ],
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context) {
    switch (status) {
      case IntakeStatus.taken:
        return _StatusChip(
          color: AppTheme.getSuccessColor(context),
          icon: FIcons.check,
        );
      case IntakeStatus.missed:
        // Don't show any icon for missed medications
        return const SizedBox.shrink();
      case IntakeStatus.pending:
        final now = TimezoneUtil.nowInPakistan();
        final parts = reminderTime.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final scheduledTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour,
          minute,
        );

        if (scheduledTime.isBefore(now)) {
          // Past time, don't show icon (status will be shown in header)
          return const SizedBox.shrink();
        } else {
          return SizedBox(
            width: 38.w,
            height: 38.w,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleMarkTaken(context),
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  decoration: ModernSurfaceTheme.frostedChip(
                    context,
                    baseColor: ModernSurfaceTheme.primaryTeal,
                  ),
                  child: Icon(
                    FIcons.plus,
                    size: 16,
                    color: ModernSurfaceTheme.chipForegroundColor(
                      ModernSurfaceTheme.primaryTeal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      case IntakeStatus.skipped:
        return _StatusChip(
          color: context.theme.colors.mutedForeground,
          icon: FIcons.minus,
        );
    }
  }

  Future<void> _handleMarkTaken(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();

    final parts = reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final scheduledTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );

    await medicationProvider.logIntake(
      medicineId: medicine.id,
      scheduledTime: scheduledTime,
      status: IntakeStatus.taken,
      userId: authProvider.currentUser!.id,
    );

    onStatusChanged?.call();
  }
}

class _PriorityBadge extends StatelessWidget {
  final MedicinePriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor(context);
    final icon = _getPriorityIcon();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              '${priority.name.toLowerCase()}'.tr(),
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(BuildContext context) {
    switch (priority) {
      case MedicinePriority.high:
        return AppTheme.getErrorColor(context);
      case MedicinePriority.medium:
        return Colors.amber[700]!;
      case MedicinePriority.low:
        return Colors.blue;
    }
  }

  IconData _getPriorityIcon() {
    switch (priority) {
      case MedicinePriority.high:
        return Icons.priority_high;
      case MedicinePriority.medium:
        return Icons.info_outline;
      case MedicinePriority.low:
        return Icons.low_priority;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _StatusChip({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
