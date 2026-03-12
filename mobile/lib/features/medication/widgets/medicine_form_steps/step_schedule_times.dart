import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/medicine_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../providers/medicine_form_provider.dart';
import '../medicine_form_shared/frequency_time_selector.dart' as custom;

class StepScheduleTimes extends StatelessWidget {
  const StepScheduleTimes({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineFormProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When do you take this medicine?',
              style: context.theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _getFrequencyDescription(provider.formData.frequency),
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            SizedBox(height: 24.h),
            _buildTimeList(context, provider),
            SizedBox(height: 16.h),
            _buildAddTimeButton(context, provider),
          ],
        );
      },
    );
  }

  String _getFrequencyDescription(frequency) {
    switch (frequency) {
      case MedicineFrequency.daily:
        return 'Set the time you take your medicine once daily';
      case MedicineFrequency.twiceDaily:
        return 'Set your morning and evening times';
      case MedicineFrequency.thriceDaily:
        return 'Set your morning, afternoon, and evening times';
      case MedicineFrequency.periodic:
        return 'Set the time for your selected days';
      case MedicineFrequency.beforeMeal:
        return 'Set times to take medicine before meals';
      case MedicineFrequency.afterMeal:
        return 'Set times to take medicine after meals';
      default:
        return 'Set your reminder times';
    }
  }

  Widget _buildTimeList(BuildContext context, MedicineFormProvider provider) {
    final times = provider.formData.reminderTimes;

    if (times.isEmpty) {
      return FCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                FIcons.clock,
                size: 48,
                color: context.theme.colors.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text('No times set yet', style: context.theme.typography.lg),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add reminder times',
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: times.asMap().entries.map((entry) {
        final index = entry.key;
        final time = entry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: index < times.length - 1 ? 12 : 0),
          child: Stack(
            children: [
              custom.FrequencyTimeSelector(
                time: time,
                onTap: () => _showTimePicker(context, provider, index),
              ),
              if (times.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => provider.removeReminderTime(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.theme.colors.destructive,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          FIcons.x,
                          size: 16,
                          color: context.theme.colors.destructiveForeground,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddTimeButton(
    BuildContext context,
    MedicineFormProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FButton(
        style: FButtonStyle.outline(),
        onPress: () => _showTimePicker(
          context,
          provider,
          provider.formData.reminderTimes.length,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FIcons.plus, size: 20, color: AppTheme.appleGreen),
            const SizedBox(width: 8),
            Text(
              'Add Another Time',
              style: TextStyle(
                color: ModernSurfaceTheme.deepTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    MedicineFormProvider provider,
    int index,
  ) async {
    final initialTime = index < provider.formData.reminderTimes.length
        ? provider.formData.reminderTimes[index]
        : const TimeOfDay(hour: 9, minute: 0);

    final selectedTime = await showFDialog<TimeOfDay>(
      context: context,
      builder: (context, style, animation) => custom.TimePickerDialog(
        initialTime: initialTime,
        style: style,
        animation: animation,
      ),
    );

    if (selectedTime != null) {
      if (index < provider.formData.reminderTimes.length) {
        provider.updateReminderTime(index, selectedTime);
      } else {
        provider.addReminderTime(selectedTime);
      }
    }
  }
}
