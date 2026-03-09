import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';

import '../../../core/theme/modern_surface_theme.dart';

class MedicineCalendarHeader extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const MedicineCalendarHeader({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: ModernSurfaceTheme.accentBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'medication.scheduleOverview'.tr(),
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 8.h),
          FLineCalendar(
            initialSelection: selectedDate,
            initialScroll: selectedDate,
            onChange: (date) => onDateChanged(date ?? DateTime.now()),
            toggleable: true,
            start: DateTime(1900),
            end: DateTime(2050),
            today: DateTime.now(),
          ),
        ],
      ),
    );
  }
}
