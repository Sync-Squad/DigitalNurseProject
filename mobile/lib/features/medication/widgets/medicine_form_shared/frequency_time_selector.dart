import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';

class FrequencyTimeSelector extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const FrequencyTimeSelector({
    super.key,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  FIcons.clock,
                  color: context.theme.colors.primary,
                  size: 20.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time.format(context),
                        style: context.theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap to edit',
                        style: context.theme.typography.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  FIcons.chevronRight,
                  color: context.theme.colors.mutedForeground,
                  size: 16.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final FDialogStyle? style;
  final Animation<double>? animation;

  const TimePickerDialog({
    super.key,
    required this.initialTime,
    this.style,
    this.animation,
  });

  @override
  State<TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: (widget.style ?? context.theme.dialogStyle).call,
      animation: widget.animation,
      title: const Text('Select Time'),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simplified time picker using buttons for common times
          _buildTimeGrid(context),
          const SizedBox(height: 24),
          // Use the built-in time picker with a button trigger
          FButton(
            onPress: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() {
                  _selectedTime = time;
                });
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FIcons.clock, size: 20),
                const SizedBox(width: 8),
                Text('Set Time: ${_selectedTime.format(context)}'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.theme.colors.foreground),
          ),
        ),
        FButton(
          onPress: () => Navigator.of(context).pop(_selectedTime),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(BuildContext context) {
    final commonTimes = [
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: commonTimes.map((time) {
        final isSelected =
            _selectedTime.hour == time.hour &&
            _selectedTime.minute == time.minute;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTime = time;
              });
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.appleGreen
                    : context.theme.colors.muted,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.appleGreen
                      : context.theme.colors.border,
                ),
              ),
              child: Text(
                time.format(context),
                style: context.theme.typography.sm.copyWith(
                  color: isSelected
                      ? Colors.white
                      : context.theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
