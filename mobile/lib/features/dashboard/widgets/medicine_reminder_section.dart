import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/medication_provider.dart';
import 'expandable_section_tile.dart';

class MedicineReminderSection extends StatelessWidget {
  const MedicineReminderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medicationProvider, child) {
        final upcomingReminders = medicationProvider.upcomingReminders;
        final todayReminders = upcomingReminders.where((reminder) {
          final reminderTime = reminder['reminderTime'] as DateTime;
          final now = DateTime.now();
          return reminderTime.year == now.year &&
              reminderTime.month == now.month &&
              reminderTime.day == now.day;
        }).toList();

        return ExpandableSectionTile(
          icon: Icons.medication_liquid, // More similar to pill capsule icon
          title: 'dashboard.medicineReminder'.tr(),
          subtitle: 'dashboard.viewDetails'.tr(),
          count: '${todayReminders.length}',
          titleColor: context.theme.colors.primary,
          routeForViewDetails: '/medications',
          interactionMode: InteractionMode.standard,
          expandedChild: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayReminders.isEmpty) ...[
                  Center(
                    child: Text(
                      'dashboard.noRemindersToday'.tr(),
                      style: TextStyle(
                        color: context.theme.colors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'dashboard.todaysReminders'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...todayReminders.take(3).map((reminder) {
                    final medicine = reminder['medicine'];
                    final time = reminder['reminderTime'] as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: context.theme.colors.muted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.theme.colors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.medication,
                              color: context.theme.colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    medicine.dosage,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: context
                                              .theme
                                              .colors
                                              .mutedForeground,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(time),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.theme.colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (todayReminders.length > 3) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'dashboard.moreReminders'.tr(
                          namedArgs: {'count': '${todayReminders.length - 3}'},
                        ),
                        style: TextStyle(
                          color: context.theme.colors.mutedForeground,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
