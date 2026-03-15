import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/medicine_model.dart';
import '../../providers/medicine_form_provider.dart';

class StepSummary extends StatefulWidget {
  const StepSummary({super.key});

  @override
  State<StepSummary> createState() => _StepSummaryState();
}

class _StepSummaryState extends State<StepSummary> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _notesController.addListener(() {
      if (mounted) {
        final provider = context.read<MedicineFormProvider>();
        provider.setNotes(_notesController.text);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineFormProvider>(
      builder: (context, provider, child) {
        final data = provider.formData;

        // Initialize controller with current notes value
        if (_notesController.text != data.notes) {
          _notesController.text = data.notes;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine & Dosage Information
            _buildCompactSummarySection(context, 'Medicine & Dosage', [
              _buildCompactSummaryItem('Name', data.name),
              _buildCompactSummaryItem('Type', _getFormText(data.medicineForm)),
              _buildCompactSummaryItem(
                'Dose',
                '${data.doseAmount} of ${data.strength}',
              ),
            ], () => provider.goToStep(0)),

            SizedBox(height: 8.h),

            // Schedule & Dates
            _buildCompactSummarySection(context, 'Schedule & Dates', [
              _buildCompactSummaryItem(
                'Frequency',
                _getFrequencyText(data.frequency),
              ),
              if (data.frequency == MedicineFrequency.periodic)
                _buildCompactSummaryItem(
                  'Days',
                  _getPeriodicDaysText(data.periodicDays),
                ),
              _buildCompactSummaryItem(
                'Times',
                _getTimesText(data.reminderTimes, context),
              ),
              _buildCompactSummaryItem(
                'Start',
                DateFormat('MMM dd, yyyy').format(data.startDate),
              ),
              if (data.endDate != null)
                _buildCompactSummaryItem(
                  'End',
                  DateFormat('MMM dd, yyyy').format(data.endDate!),
                ),
              _buildCompactSummaryItem(
                'Priority',
                _getPriorityText(data.priority),
              ),
            ], () => provider.goToStep(1)),

            SizedBox(height: 8.h),

            // Compact Notes section
            _buildCompactNotesSection(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildCompactSummarySection(
    BuildContext context,
    String title,
    List<Widget> items,
    VoidCallback onEdit,
  ) {
    return FCard(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FButton(
                  style: FButtonStyle.outline(),
                  onPress: onEdit,
                  child: Text(
                    'Edit',
                    style: TextStyle(color: context.theme.colors.foreground),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummaryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: context.theme.typography.xs.copyWith(
                fontWeight: FontWeight.w500,
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.theme.typography.xs.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNotesSection(
    BuildContext context,
    MedicineFormProvider provider,
  ) {
    return FCard(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes (Optional)',
              style: context.theme.typography.sm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            FTextField(
              controller: _notesController,
              hint: 'Add notes...',
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  String _getFormText(MedicineForm? form) {
    if (form == null) return 'Not selected';

    switch (form) {
      case MedicineForm.tablet:
        return 'Tablet';
      case MedicineForm.capsule:
        return 'Capsule';
      case MedicineForm.syrup:
        return 'Syrup';
      case MedicineForm.injection:
        return 'Injection';
      case MedicineForm.drops:
        return 'Drops';
      case MedicineForm.inhaler:
        return 'Inhaler';
      case MedicineForm.other:
        return 'Other';
    }
  }

  String _getFrequencyText(MedicineFrequency? frequency) {
    if (frequency == null) return 'Not selected';

    switch (frequency) {
      case MedicineFrequency.daily:
        return 'Once Daily';
      case MedicineFrequency.twiceDaily:
        return 'Twice Daily';
      case MedicineFrequency.thriceDaily:
        return '3 Times Daily';
      case MedicineFrequency.periodic:
        return 'Periodic';
      case MedicineFrequency.weekly:
        return 'Weekly';
      case MedicineFrequency.asNeeded:
        return 'As Needed';
      case MedicineFrequency.beforeMeal:
        return 'Before Meal';
      case MedicineFrequency.afterMeal:
        return 'After Meal';
    }
  }

  String _getPeriodicDaysText(List<int> days) {
    if (days.isEmpty) return 'No days selected';

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(days);
    sortedDays.sort((a, b) {
      final aOrder = a == 7 ? 0 : a;
      final bOrder = b == 7 ? 0 : b;
      return aOrder.compareTo(bOrder);
    });

    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  String _getTimesText(List<TimeOfDay> times, BuildContext context) {
    if (times.isEmpty) return 'No times set';

    return times.map((time) => time.format(context)).join(', ');
  }

  String _getPriorityText(MedicinePriority priority) {
    switch (priority) {
      case MedicinePriority.low:
        return 'Low (Silent)';
      case MedicinePriority.medium:
        return 'Medium (Standard)';
      case MedicinePriority.high:
        return 'High (Full-screen Alarm)';
    }
  }
}
