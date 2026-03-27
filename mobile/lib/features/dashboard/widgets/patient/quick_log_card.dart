import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/care_context_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_util.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../../../core/models/medicine_model.dart';
import '../../../medication/widgets/intake_log_bottom_sheet.dart';
import '../../../medication/widgets/missed_remarks_bottom_sheet.dart';

class QuickLogCard extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final void Function(IntakeStatus status) onLogged;

  const QuickLogCard({
    super.key,
    required this.reminder,
    required this.onLogged,
  });

  @override
  State<QuickLogCard> createState() => _QuickLogCardState();
}

class _QuickLogCardState extends State<QuickLogCard> with SingleTickerProviderStateMixin {
  bool _isLogging = false;

  Future<void> _handleStatus(BuildContext context, IntakeStatus status) async {
    if (_isLogging) return;

    final authProvider = context.read<AuthProvider>();
    final medProvider = context.read<MedicationProvider>();
    final careContext = context.read<CareContextProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final medicine = widget.reminder['medicine'] as MedicineModel?;
    final scheduledTime = widget.reminder['reminderTime'] as DateTime?;
    if (medicine == null || scheduledTime == null) return;

    Map<String, dynamic>? result;

    if (status == IntakeStatus.taken) {
      result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => IntakeLogBottomSheet(
          medicine: medicine,
          scheduledTime: scheduledTime,
        ),
      );
    } else if (status == IntakeStatus.missed) {
      result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MissedRemarksBottomSheet(
          medicine: medicine,
        ),
      );
    }

    if (result == null) return;

    setState(() => _isLogging = true);
    HapticFeedback.mediumImpact();

    try {
      // Optimistically hide from dashboard
      widget.onLogged(result['status']);

      final success = await medProvider.logIntake(
        medicineId: medicine.id,
        scheduledTime: scheduledTime,
        status: result['status'],
        takenTime: result['takenTime'],
        note: result['note'],
        userId: user.id,
        elderUserId: careContext.selectedElderId,
      );

      if (success && mounted) {
        final timeStr = result['takenTime'] != null 
            ? TimezoneUtil.formatInPakistan(result['takenTime'], format: 'h:mm a')
            : 'Scheduled Time';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['status'] == IntakeStatus.taken 
                  ? 'Marked taken at $timeStr'
                  : 'Marked as missed',
            ),
            backgroundColor: result['status'] == IntakeStatus.taken 
                ? const Color(0xFF1CB5A9) 
                : Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update medication status.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicine = widget.reminder['medicine'] as MedicineModel?;
    final DateTime? time = widget.reminder['reminderTime'] as DateTime?;

    if (medicine == null || time == null) {
      return const SizedBox.shrink();
    }

    final bool isHighPriority = medicine.priority == MedicinePriority.high;
    final String name = medicine.name;
    final timeStr = TimezoneUtil.formatInPakistan(time, format: 'h:mm a');

    final Color cardColor = isHighPriority ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1); // Light Red vs Light Amber
    final Color accentColor = isHighPriority ? Colors.red : Colors.amber;
    final Color textColor = isHighPriority ? Colors.red[900]! : Colors.brown[900]!;

    return Container(
      margin: EdgeInsets.only(right: 8.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // Colored Accent
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4.w,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isHighPriority 
                      ? [Colors.red, Colors.redAccent]
                      : [Colors.amber, Colors.orangeAccent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 6.w, 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_filled, size: 8.sp, color: accentColor),
                            SizedBox(width: 3.w),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              () {
                                final hour = time.hour;
                                if (hour >= 5 && hour < 12) return 'medication.timeOfDay.morning'.tr();
                                if (hour >= 12 && hour < 17) return 'medication.timeOfDay.afternoon'.tr();
                                return 'medication.timeOfDay.evening'.tr();
                              }(),
                              style: TextStyle(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w800,
                                color: accentColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isHighPriority)
                        Icon(
                          Icons.warning_rounded,
                          size: 12.sp,
                          color: Colors.red,
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(),
                  if (_isLogging)
                    Center(
                      child: SizedBox(
                        height: 16.h,
                        width: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: accentColor,
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isHighPriority && time.isBefore(TimezoneUtil.nowInPakistan()))
                                Text(
                                  () {
                                    final diff = TimezoneUtil.nowInPakistan().difference(time);
                                    if (diff.inHours > 0) {
                                      return '${diff.inHours}h overdue';
                                    }
                                    return '${diff.inMinutes}m overdue';
                                  }(),
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red[700],
                                  ),
                                ),
                              Row(
                                children: [
                                  _ActionButton(
                                    icon: Icons.close_rounded,
                                    color: Colors.redAccent,
                                    isSelected: widget.reminder['status'] == 'missed',
                                    onTap: () => _handleStatus(context, IntakeStatus.missed),
                                  ),
                                  SizedBox(width: 8.w),
                                  _ActionButton(
                                    icon: Icons.check_rounded,
                                    color: const Color(0xFF1CB5A9),
                                    isSelected: widget.reminder['status'] == 'taken',
                                    onTap: () => _handleStatus(context, IntakeStatus.taken),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          shape: BoxShape.circle,
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: Icon(
          icon,
          size: 14.sp,
          color: isSelected ? Colors.white : color,
        ),
      ),
    );
  }
}
