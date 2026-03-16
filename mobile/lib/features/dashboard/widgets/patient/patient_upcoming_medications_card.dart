import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/medicine_model.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/utils/timezone_util.dart';
import '../dashboard_theme.dart';
import 'expandable_patient_card.dart';

class PatientUpcomingMedicationsCard extends StatelessWidget {
  const PatientUpcomingMedicationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final medicationProvider = context.watch<MedicationProvider>();
    final upcoming = [...medicationProvider.upcomingReminders]
      ..sort((a, b) {
        final aTime = a['reminderTime'] as DateTime;
        final bTime = b['reminderTime'] as DateTime;
        return aTime.compareTo(bTime);
      });

    final now = TimezoneUtil.nowInPakistan();
    final nextReminders = upcoming.where((reminder) {
      final time = reminder['reminderTime'] as DateTime;
      return !time.isBefore(now);
    }).toList();

    final visibleReminders = nextReminders.take(4).toList();

    final brightness = Theme.of(context).brightness;

    return ExpandablePatientCard(
      icon: Icons.medication_liquid_outlined,
      title: 'patient.upcomingMedicines'.tr(),
      subtitle: 'patient.upcomingSubtitle'.tr(),
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
                      'patient.noUpcomingDoses'.tr(),
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
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final accent = isSoon
        ? CaregiverDashboardTheme.accentCoral
        : CaregiverDashboardTheme.accentBlue;
    final timeLabel = DateFormat('h:mm a').format(time);
    final dayLabel = DateFormat('MMM d').format(time);
    final diff = time.difference(TimezoneUtil.nowInPakistan());
    final relative = diff.inMinutes <= 0
        ? 'patient.dueNow'.tr()
        : diff.inMinutes < 60
        ? 'patient.inMinutes'.tr(namedArgs: {'count': '${diff.inMinutes}'})
        : diff.inHours < 24
        ? 'patient.inHours'.tr(namedArgs: {'count': '${diff.inHours}'})
        : 'patient.inDays'.tr(namedArgs: {'count': '${diff.inDays}'});

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
                onPressed: () => context.push('/medications'),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: context.theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  isSoon ? 'patient.remindNow'.tr() : 'patient.details'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
