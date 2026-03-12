import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/medicine_model.dart';
import '../../../../core/providers/medication_provider.dart';
import '../dashboard_theme.dart';
import '../patient/expandable_patient_card.dart';

class CaregiverUpcomingMedicationsCard extends StatelessWidget {
  const CaregiverUpcomingMedicationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final upcoming = [...medicationProvider.upcomingReminders]
      ..sort((a, b) {
        final aTime = a['reminderTime'] as DateTime;
        final bTime = b['reminderTime'] as DateTime;
        return aTime.compareTo(bTime);
      });

    final now = DateTime.now();
    final nextReminders = upcoming.where((reminder) {
      final time = reminder['reminderTime'] as DateTime;
      return !time.isBefore(now);
    }).toList();

    final visibleReminders = nextReminders.take(4).toList();

    final brightness = Theme.of(context).brightness;

    return ExpandablePatientCard(
      icon: Icons.medication_liquid_outlined,
      title: 'Upcoming Medicines',
      subtitle: 'Stay prepared with the next doses in the queue.',
      count: '${nextReminders.length}',
      accentColor: CaregiverDashboardTheme.accentBlue,
      routeForViewDetails: '/medications',
      expandedChild: nextReminders.isEmpty
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: CaregiverDashboardTheme.tintedCard(
                context,
                CaregiverDashboardTheme.primaryTeal,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: CaregiverDashboardTheme.iconBadge(
                      context,
                      CaregiverDashboardTheme.primaryTeal,
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'No upcoming doses scheduled.',
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CaregiverDashboardTheme.tintedForegroundColor(
                          CaregiverDashboardTheme.primaryTeal,
                          brightness: brightness,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...visibleReminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reminder = entry.value;
                  final medicine = reminder['medicine'] as MedicineModel;
                  final time = reminder['reminderTime'] as DateTime;
                  final isSoon = time.difference(now).inMinutes <= 30;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == visibleReminders.length - 1 ? 0 : 14.h,
                    ),
                    child: _UpcomingReminderRow(
                      medicine: medicine,
                      time: time,
                      isSoon: isSoon,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _UpcomingReminderRow extends StatelessWidget {
  final MedicineModel medicine;
  final DateTime time;
  final bool isSoon;

  const _UpcomingReminderRow({
    required this.medicine,
    required this.time,
    required this.isSoon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSoon
        ? CaregiverDashboardTheme.accentCoral
        : CaregiverDashboardTheme.accentBlue;
    final timeLabel = DateFormat('h:mm a').format(time);
    final dayLabel = DateFormat('MMM d').format(time);
    final diff = time.difference(DateTime.now());
    final relative = diff.inMinutes <= 0
        ? 'Due now'
        : diff.inMinutes < 60
        ? 'In ${diff.inMinutes} min'
        : diff.inHours < 24
        ? 'In ${diff.inHours} hrs'
        : 'In ${diff.inDays} days';

    final brightness = Theme.of(context).brightness;
    final onTint = CaregiverDashboardTheme.tintedForegroundColor(
      accent,
      brightness: brightness,
    );
    final onTintMuted = CaregiverDashboardTheme.tintedMutedColor(
      accent,
      brightness: brightness,
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: CaregiverDashboardTheme.tintedCard(context, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: CaregiverDashboardTheme.iconBadge(context, accent),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onTint,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      medicine.dosage,
                      style: context.theme.typography.xs.copyWith(
                        color: onTintMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: CaregiverDashboardTheme.frostedChip(
                  context,
                  baseColor: Colors.white,
                ),
                child: Text(
                  relative,
                  style: context.theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$dayLabel • $timeLabel',
                style: context.theme.typography.xs.copyWith(color: onTintMuted),
              ),
              TextButton(
                onPressed: () {
                  if (isSoon) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reminder sent for ${medicine.name}'),
                      ),
                    );
                  } else {
                    context.push('/medications');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: context.theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(isSoon ? 'Remind now' : 'Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
