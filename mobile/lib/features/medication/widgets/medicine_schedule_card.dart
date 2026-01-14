import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import 'medicine_item_tile.dart';

enum MedicineTimeOfDay { morning, afternoon, evening }

class MedicineScheduleCard extends StatefulWidget {
  final MedicineTimeOfDay timeOfDay;
  final List<MedicineModel> medicines;
  final DateTime selectedDate;
  final VoidCallback? onStatusChanged;

  const MedicineScheduleCard({
    super.key,
    required this.timeOfDay,
    required this.medicines,
    required this.selectedDate,
    this.onStatusChanged,
  });

  @override
  State<MedicineScheduleCard> createState() => _MedicineScheduleCardState();
}

class _MedicineScheduleCardState extends State<MedicineScheduleCard> {
  bool _isExpanded = false;
  Map<String, IntakeStatus> _medicineStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadStatuses();
    // Listen to medication provider changes to refresh statuses
    _setupProviderListener();
  }

  void _setupProviderListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final medicationProvider = context.read<MedicationProvider>();
        medicationProvider.addListener(_onMedicationProviderUpdate);
      }
    });
  }

  void _onMedicationProviderUpdate() {
    if (mounted) {
      _loadStatuses();
    }
  }

  @override
  void dispose() {
    // Remove the listener when disposing
    try {
      context.read<MedicationProvider>().removeListener(_onMedicationProviderUpdate);
    } catch (e) {
      // Ignore if already disposed
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MedicineScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicines != widget.medicines ||
        oldWidget.selectedDate != widget.selectedDate) {
      _loadStatuses();
    }
  }

  Future<void> _loadStatuses() async {
    final medicationProvider = context.read<MedicationProvider>();
    final statuses = <String, IntakeStatus>{};

    for (final medicine in widget.medicines) {
      for (final reminderTime in medicine.reminderTimes) {
        final key = '${medicine.id}_$reminderTime';
        final status = await medicationProvider.getMedicineStatus(
          medicine,
          reminderTime,
          widget.selectedDate,
        );
        statuses[key] = status;
      }
    }

    if (mounted) {
      setState(() {
        _medicineStatuses = statuses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.medicines.isEmpty) return const SizedBox.shrink();

    final timeInfo = _getTimeInfo(context);
    final chipForeground =
        ModernSurfaceTheme.chipForegroundColor(timeInfo.color);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context, accent: timeInfo.color),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: ModernSurfaceTheme.iconBadge(context, timeInfo.color),
                    child: Icon(
                      timeInfo.icon,
                      color: onPrimary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeInfo.label,
                          style: textTheme.titleMedium?.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _getStatusText(context),
                          style: textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusIcon(context),
                  SizedBox(width: 12.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: ModernSurfaceTheme.frostedChip(
                      context,
                      baseColor: timeInfo.color,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.medicines.length.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: chipForeground,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          _isExpanded ? FIcons.chevronUp : FIcons.chevronDown,
                          size: 14,
                      color: chipForeground,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(
              height: 24.h,
              color: onSurface.withValues(alpha: 0.08),
            ),
            Column(
              children: widget.medicines
                  .map((medicine) {
                    final relevantTimes = medicine.reminderTimes
                        .where((time) => _isRelevantTimeOfDay(time))
                        .toList();

                    return relevantTimes.map((time) {
                      final key = '${medicine.id}_$time';
                      final status =
                          _medicineStatuses[key] ?? IntakeStatus.pending;

                      return MedicineItemTile(
                        medicine: medicine,
                        reminderTime: time,
                        status: status,
                        selectedDate: widget.selectedDate,
                        onStatusChanged: () {
                          _loadStatuses();
                          widget.onStatusChanged?.call();
                        },
                      );
                    }).toList();
                  })
                  .expand((x) => x)
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  bool _isRelevantTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]);
    if (hour == null) return false;

    switch (widget.timeOfDay) {
      case MedicineTimeOfDay.morning:
        return hour < 12;
      case MedicineTimeOfDay.afternoon:
        return hour >= 12 && hour < 17;
      case MedicineTimeOfDay.evening:
        return hour >= 17;
    }
  }

  Widget _buildStatusIcon(BuildContext context) {
    if (_medicineStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    final statusList = _medicineStatuses.values.toList();
    final takenCount = statusList.where((s) => s == IntakeStatus.taken).length;
    final missedCount = statusList.where((s) => s == IntakeStatus.missed).length;
    final pendingCount = statusList.where((s) => s == IntakeStatus.pending).length;
    final total = statusList.length;

    // If all taken, show check icon
    if (takenCount == total) {
      return _StatusBadge(
        color: AppTheme.getSuccessColor(context),
        icon: FIcons.check,
      );
    }

    // If any explicitly marked as missed, don't show an icon
    if (missedCount > 0) {
      return const SizedBox.shrink();
    }

    // Check if we're looking at today's date to determine if pending items are overdue
    final isToday = widget.selectedDate.year == DateTime.now().year &&
        widget.selectedDate.month == DateTime.now().month &&
        widget.selectedDate.day == DateTime.now().day;

    // Only check for overdue if we're viewing today's medications
    if (isToday && pendingCount > 0) {
      final now = DateTime.now();
      int overdueCount = 0;

      for (final entry in _medicineStatuses.entries) {
        if (entry.value == IntakeStatus.pending) {
          final timePart = entry.key.split('_').last;
          final parts = timePart.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            final scheduledTime = DateTime(
              widget.selectedDate.year,
              widget.selectedDate.month,
              widget.selectedDate.day,
              hour,
              minute,
            );
            if (scheduledTime.isBefore(now)) {
              overdueCount++;
            }
          }
        }
      }

      // If any are overdue, don't show an icon (text will show "Missed")
      if (overdueCount > 0) {
        return const SizedBox.shrink();
      }
    }

    // If any pending (not overdue), show clock icon
    if (pendingCount > 0) {
      return _StatusBadge(
        color: context.theme.colors.primary,
        icon: FIcons.clock,
      );
    }

    // If any taken but not all, show check icon
    if (takenCount > 0) {
      return _StatusBadge(
        color: AppTheme.getSuccessColor(context),
        icon: FIcons.check,
      );
    }

    return const SizedBox.shrink();
  }

  String _getStatusText(BuildContext context) {
    if (_medicineStatuses.isEmpty) {
      return 'No medicines';
    }

    final statusList = _medicineStatuses.values.toList();
    final takenCount = statusList.where((s) => s == IntakeStatus.taken).length;
    final missedCount = statusList.where((s) => s == IntakeStatus.missed).length;
    final pendingCount = statusList.where((s) => s == IntakeStatus.pending).length;
    final total = statusList.length;

    // If all taken, show "Taken"
    if (takenCount == total) {
      return 'Taken';
    }

    // If any explicitly marked as missed, show "Missed"
    if (missedCount > 0) {
      return 'Missed';
    }

    // Check if we're looking at today's date to determine if pending items are overdue
    final isToday = widget.selectedDate.year == DateTime.now().year &&
        widget.selectedDate.month == DateTime.now().month &&
        widget.selectedDate.day == DateTime.now().day;

    // Only check for overdue if we're viewing today's medications
    if (isToday && pendingCount > 0) {
      final now = DateTime.now();
      int overdueCount = 0;

      for (final entry in _medicineStatuses.entries) {
        if (entry.value == IntakeStatus.pending) {
          final timePart = entry.key.split('_').last;
          final parts = timePart.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            final scheduledTime = DateTime(
              widget.selectedDate.year,
              widget.selectedDate.month,
              widget.selectedDate.day,
              hour,
              minute,
            );
            if (scheduledTime.isBefore(now)) {
              overdueCount++;
            }
          }
        }
      }

      // If any are overdue, show "Missed"
      if (overdueCount > 0) {
        return 'Missed';
      }
    }

    // If any pending (not overdue), show "Upcoming"
    if (pendingCount > 0) {
      return 'Upcoming';
    }

    // If any taken but not all
    if (takenCount > 0) {
      return '$takenCount of $total taken';
    }

    return 'Upcoming';
  }

  ({String label, IconData icon, Color color}) _getTimeInfo(
    BuildContext context,
  ) {
    switch (widget.timeOfDay) {
      case MedicineTimeOfDay.morning:
        return (label: 'Morning', icon: FIcons.sunrise, color: ModernSurfaceTheme.accentYellow);
      case MedicineTimeOfDay.afternoon:
        // Use a more vibrant teal for better visibility in the chip
        // Using a brighter, more saturated teal (similar vibrancy to accentYellow/accentBlue)
        return (label: 'Afternoon', icon: FIcons.sun, color: const Color(0xFF14C4B3));
      case MedicineTimeOfDay.evening:
        return (label: 'Evening', icon: FIcons.moon, color: ModernSurfaceTheme.accentBlue);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _StatusBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
