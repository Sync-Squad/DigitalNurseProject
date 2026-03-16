import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_util.dart';
import '../../providers/medicine_form_provider.dart';

class StepStartDate extends StatefulWidget {
  const StepStartDate({super.key});

  @override
  State<StepStartDate> createState() => _StepStartDateState();
}

class _StepStartDateState extends State<StepStartDate> {
  bool _hasEndDate = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MedicineFormProvider>();
    _hasEndDate = provider.formData.endDate != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<MedicineFormProvider>();
    final hasEndDate = provider.formData.endDate != null;
    if (_hasEndDate != hasEndDate) {
      setState(() {
        _hasEndDate = hasEndDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineFormProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When do you start taking this medicine?',
              style: context.theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            _buildDateCards(context, provider),
            SizedBox(height: 24.h),
            _buildEndDateToggle(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildDateCards(BuildContext context, MedicineFormProvider provider) {
    return Column(
      children: [
        // Start Date
        _buildDateCard(
          context,
          title: 'Start Date',
          subtitle: 'When you begin taking this medicine',
          date: provider.formData.startDate,
          onTap: () => _selectStartDate(context, provider),
          icon: FIcons.calendar,
        ),

        // End Date (conditional)
        if (_hasEndDate) ...[
          const SizedBox(height: 16),
          _buildDateCard(
            context,
            title: 'End Date (Optional)',
            subtitle: 'When to stop taking this medicine',
            date: provider.formData.endDate,
            onTap: () => _selectEndDate(context, provider),
            icon: FIcons.calendarX,
            isOptional: true,
            onRemove: () {
              setState(() {
                _hasEndDate = false;
              });
              provider.setEndDate(null);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
    bool isOptional = false,
    VoidCallback? onRemove,
  }) {
    final dateText = date != null
        ? DateFormat('MMM dd, yyyy').format(date)
        : 'Select date';

    return FCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.appleGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.appleGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: context.theme.typography.lg.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (onRemove != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onRemove,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    FIcons.x,
                                    size: 16,
                                    color: context.theme.colors.destructive,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.theme.typography.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateText,
                        style: context.theme.typography.base.copyWith(
                          color: AppTheme.appleGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  FIcons.chevronRight,
                  color: context.theme.colors.mutedForeground,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndDateToggle(
    BuildContext context,
    MedicineFormProvider provider,
  ) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set End Date',
                    style: context.theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Do you know when you\'ll stop taking this medicine?',
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              child: Switch(
                value: _hasEndDate,
                onChanged: (value) {
                  setState(() {
                    _hasEndDate = value;
                  });
                  if (!value) {
                    provider.setEndDate(null);
                  } else {
                    // Set a default end date (30 days from start)
                    provider.setEndDate(
                      provider.formData.startDate.add(const Duration(days: 30)),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(
    BuildContext context,
    MedicineFormProvider provider,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: provider.formData.startDate,
      firstDate: TimezoneUtil.nowInPakistan().subtract(const Duration(days: 365)),
      lastDate: TimezoneUtil.nowInPakistan().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      provider.setStartDate(selectedDate);
    }
  }

  Future<void> _selectEndDate(
    BuildContext context,
    MedicineFormProvider provider,
  ) async {
    final initialDate =
        provider.formData.endDate ??
        provider.formData.startDate.add(const Duration(days: 30));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: provider.formData.startDate,
      lastDate: TimezoneUtil.nowInPakistan().add(const Duration(days: 365 * 2)),
    );

    if (selectedDate != null) {
      provider.setEndDate(selectedDate);
    }
  }
}
