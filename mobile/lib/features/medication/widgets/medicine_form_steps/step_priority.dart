import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/medicine_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../providers/medicine_form_provider.dart';

class StepPriority extends StatelessWidget {
  const StepPriority({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineFormProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Reminder Priority',
              style: context.theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'How would you like to be notified for this medicine?',
              style: context.theme.typography.base.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            SizedBox(height: 24.h),
            _buildPriorityOptions(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildPriorityOptions(
    BuildContext context,
    MedicineFormProvider provider,
  ) {
    final priorityOptions = [
      _PriorityOption(
        MedicinePriority.low,
        'Low Priority',
        'Silent notification in the tray. Good for vitamins or supplements.',
        FIcons.bellOff,
        const Color(0xFF9E9E9E),
      ),
      _PriorityOption(
        MedicinePriority.medium,
        'Medium Priority',
        'Standard notification with sound. Regular routine medications.',
        FIcons.bell,
        AppTheme.appleGreen,
      ),
      _PriorityOption(
        MedicinePriority.high,
        'High Priority',
        'Full-screen alarm that overrides other apps. Critical life-saving meds.',
        FIcons.triangleAlert,
        const Color(0xFFE53935),
      ),
    ];

    return Column(
      children: priorityOptions.map((option) {
        final isSelected = provider.formData.priority == option.priority;

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => provider.setPriority(option.priority),
              borderRadius: BorderRadius.circular(16.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? option.color
                        : context.theme.colors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  color: isSelected
                      ? option.color.withOpacity(0.1)
                      : context.theme.colors.muted,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? option.color
                              : context.theme.colors.muted,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(
                          option.icon,
                          color: isSelected
                              ? Colors.white
                              : context.theme.colors.mutedForeground,
                          size: 24.r,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              style: context.theme.typography.base.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? option.color
                                    : context.theme.colors.foreground,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              option.description,
                              style: context.theme.typography.sm.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: Icon(
                            FIcons.check,
                            color: option.color,
                            size: 20.r,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PriorityOption {
  final MedicinePriority priority;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _PriorityOption(
    this.priority,
    this.title,
    this.description,
    this.icon,
    this.color,
  );
}
