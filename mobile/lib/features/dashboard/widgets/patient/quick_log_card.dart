import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/care_context_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_util.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../../../core/models/medicine_model.dart';

class QuickLogCard extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onLogged;

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

    setState(() => _isLogging = true);
    HapticFeedback.mediumImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicationProvider>();
      final careContext = context.read<CareContextProvider>();
      
      final user = authProvider.currentUser;
      if (user == null) return;

      final String? medicineId = (widget.reminder['medicine'] as MedicineModel?)?.id;
      final DateTime? scheduledTime = widget.reminder['reminderTime'] as DateTime?;
      
      if (medicineId == null || scheduledTime == null) return;
      
      // Only optimistically hide if NOT (Missed AND High priority)
      final medicine = widget.reminder['medicine'] as MedicineModel?;
      final bool isHighPriority = medicine?.priority == MedicinePriority.high;
      
      if (status != IntakeStatus.missed || !isHighPriority) {
        widget.onLogged();
      }

      final success = await medProvider.logIntake(
        medicineId: medicineId,
        scheduledTime: scheduledTime,
        status: status,
        userId: user.id,
        elderUserId: careContext.selectedElderId,
      );

      // If it failed and we optimistically hid it, we might want to refresh, 
      // but for now let's just show the error.

      if (!success && mounted) {
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
      width: 135.w,
      margin: EdgeInsets.only(right: 12.w),
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
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
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
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
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
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(),
                  if (_isLogging)
                    Center(
                      child: SizedBox(
                        height: 20.h,
                        width: 20.h,
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
                                    fontSize: 9.sp,
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
                                    color: AppTheme.appleGreen,
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
          size: 16.sp,
          color: isSelected ? Colors.white : color,
        ),
      ),
    );
  }
}
