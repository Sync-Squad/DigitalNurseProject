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

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final dueRemindersList = medProvider.dueReminders;
    print('📦 DueRemindersRow rebuild. Found ${dueRemindersList.length} reminders in provider.');
    
    final dueReminders = [...dueRemindersList];
    
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

    if (medProvider.upcomingReminders.isEmpty) {
      return const SizedBox.shrink(); // No reminders at all from service
    }

    if (dueReminders.isEmpty) {
      // Reminders exist but none are "due" in this window
      // Let's show a small placeholder or nothing as per UX
      return const SizedBox.shrink(); 
    }

    return Container(
      height: 150.h,
      decoration: BoxDecoration(
        color: const Color(0xFF4CC7BB).withValues(alpha: 0.8), // 20% Lighter than Health Overview (0xFF1FB9AA)
        borderRadius: BorderRadius.circular(20.r),
      ),
      clipBehavior: Clip.antiAlias, // Ensures cards don't show outside the box
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'medication.dueNow'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 15.sp,
                  letterSpacing: -0.5,
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
                    color: const Color(0xFF071D1C),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              SizedBox(
                height: 98.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dueReminders.length,
                  clipBehavior: Clip.none,
                  itemBuilder: (context, index) {
                    final reminder = dueReminders[index];
                    final medicine = reminder['medicine'] as MedicineModel;
                    final scheduled = reminder['reminderTime'] as DateTime;
                    final scheduledUtc = scheduled.toUtc();
                    final String id = "${medicine.id}_${scheduledUtc.year}_${scheduledUtc.month}_${scheduledUtc.day}_${scheduledUtc.hour}_${scheduledUtc.minute}";

                    return QuickLogCard(
                      reminder: reminder,
                      onLogged: (status) {
                        print('🖱️ User action on Dashboard: ID=$id, Status=$status');
                        medProvider.markReminderActioned(id, status);
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
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: const Color(0xFF071D1C), // Dark and readable
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
