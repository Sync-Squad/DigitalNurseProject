import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/horizontal_modern_calendar.dart';

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
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: ModernSurfaceTheme.accentBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'medication.scheduleOverview'.tr(),
              style: ModernSurfaceTheme.sectionTitleStyle(context),
            ),
          ),
          SizedBox(height: 12.h),
          HorizontalModernCalendar(
            selectedDate: selectedDate,
            onDateChanged: onDateChanged,
          ),
        ],
      ),
    );
  }
}

