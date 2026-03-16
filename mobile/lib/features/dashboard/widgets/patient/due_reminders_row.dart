import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/utils/timezone_util.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../../../core/models/medicine_model.dart';
import 'quick_log_card.dart';

class DueRemindersRow extends StatefulWidget {
  const DueRemindersRow({super.key});

  @override
  State<DueRemindersRow> createState() => _DueRemindersRowState();
}

class _DueRemindersRowState extends State<DueRemindersRow> {
  final Set<String> _removedIds = {};

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final allReminders = medProvider.upcomingReminders;
    
    // Filter for "Due Now" (e.g., scheduled time is in the past or within next 12 hours)
    // AND not already optimistically removed
    final now = TimezoneUtil.nowInPakistan();
    final dueReminders = allReminders.where((r) {
      final medicine = r['medicine'] as MedicineModel?;
      final DateTime? scheduled = r['reminderTime'] as DateTime?;

      if (medicine == null || scheduled == null) return false;
      
      final String id = "${medicine.id}_${scheduled.millisecondsSinceEpoch}";
      
      if (_removedIds.contains(id)) return false;
      
      // Show if it's due within last 12 hours (overdue) or next 30 mins (upcoming)
      return scheduled.isAfter(now.subtract(const Duration(hours: 12))) && 
             scheduled.isBefore(now.add(const Duration(minutes: 30)));
    }).toList();

    // Sort: High Priority first, then by time
    dueReminders.sort((a, b) {
      final medA = a['medicine'] as MedicineModel;
      final medB = b['medicine'] as MedicineModel;
      final timeA = a['reminderTime'] as DateTime;
      final timeB = b['reminderTime'] as DateTime;

      if (medA.priority == MedicinePriority.high && medB.priority != MedicinePriority.high) {
        return -1;
      }
      if (medB.priority == MedicinePriority.high && medA.priority != MedicinePriority.high) {
        return 1;
      }
      return timeA.compareTo(timeB);
    });

    if (allReminders.isEmpty) {
      return const SizedBox.shrink(); // No reminders at all from service
    }

    if (dueReminders.isEmpty) {
      // Reminders exist but none are "due" in this window
      // Let's show a small placeholder or nothing as per UX
      return const SizedBox.shrink(); 
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1FB9AA).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20.r),
      ),
      clipBehavior: Clip.antiAlias, // Ensures cards don't show outside the box
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Medication Due Now'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${dueReminders.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Stack(
            children: [
              SizedBox(
                height: 85.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dueReminders.length,
                  clipBehavior: Clip.none,
                  itemBuilder: (context, index) {
                    final reminder = dueReminders[index];
                    final medicine = reminder['medicine'] as MedicineModel;
                    final scheduled = reminder['reminderTime'] as DateTime;
                    final String id = "${medicine.id}_${scheduled.millisecondsSinceEpoch}";

                    return QuickLogCard(
                      reminder: reminder,
                      onLogged: () {
                        setState(() {
                          _removedIds.add(id);
                        });
                      },
                    );
                  },
                ),
              ),
              if (dueReminders.length > 2)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 32.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF1FB9AA).withValues(alpha: 0.0),
                          const Color(0xFF1FB9AA).withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
