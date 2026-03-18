import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/models/medicine_model.dart';
import 'quick_log_card.dart';

class MissedRemindersRow extends StatefulWidget {
  const MissedRemindersRow({super.key});

  @override
  State<MissedRemindersRow> createState() => _MissedRemindersRowState();
}

class _MissedRemindersRowState extends State<MissedRemindersRow> {

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final missedReminders = medProvider.recentlyMissedReminders;

    if (missedReminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 16.h),
      decoration: BoxDecoration(
        color: Colors.red[50]!.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'RecentlyMissed'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.red[900],
                ),
              ),
              const Spacer(),
              Text(
                '${missedReminders.length}',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 110.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: missedReminders.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final reminder = missedReminders[index];
                final medicine = reminder['medicine'] as MedicineModel;
                final scheduled = reminder['reminderTime'] as DateTime;
                final scheduledUtc = scheduled.toUtc();
                final String id = "${medicine.id}_${scheduledUtc.year}_${scheduledUtc.month}_${scheduledUtc.day}_${scheduledUtc.hour}_${scheduledUtc.minute}";

                return QuickLogCard(
                  reminder: reminder,
                  onLogged: (status) {
                    medProvider.markReminderActioned(id, status);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
