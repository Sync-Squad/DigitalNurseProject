import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/timezone_util.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/medicine_model.dart';

class IntakeLogBottomSheet extends StatefulWidget {
  final MedicineModel medicine;
  final DateTime scheduledTime;

  const IntakeLogBottomSheet({
    super.key,
    required this.medicine,
    required this.scheduledTime,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required MedicineModel medicine,
    required DateTime scheduledTime,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IntakeLogBottomSheet(
        medicine: medicine,
        scheduledTime: scheduledTime,
      ),
    );
  }

  @override
  State<IntakeLogBottomSheet> createState() => _IntakeLogBottomSheetState();
}

class _IntakeLogBottomSheetState extends State<IntakeLogBottomSheet> {
  DateTime? _customTime;
  String _selectedOption = 'scheduled'; // 'scheduled', 'now', 'custom'

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Mark as Taken',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${widget.medicine.name} - ${widget.medicine.dosage}',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),
          _buildOption(
            id: 'scheduled',
            title: 'At scheduled time',
            subtitle: TimezoneUtil.formatInPakistan(widget.scheduledTime, format: 'h:mm a'),
            icon: Icons.calendar_today_rounded,
          ),
          _buildOption(
            id: 'now',
            title: 'Take now',
            subtitle: TimezoneUtil.formatInPakistan(TimezoneUtil.nowInPakistan(), format: 'h:mm a'),
            icon: Icons.bolt_rounded,
          ),
          _buildOption(
            id: 'custom',
            title: 'Choose custom time',
            subtitle: _customTime != null 
                ? TimezoneUtil.formatInPakistan(_customTime!, format: 'h:mm a')
                : 'Select time',
            icon: Icons.access_time_rounded,
            onTap: _pickCustomTime,
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: () {
                DateTime finalTime;
                if (_selectedOption == 'scheduled') {
                  finalTime = widget.scheduledTime;
                } else if (_selectedOption == 'now') {
                  finalTime = TimezoneUtil.nowInPakistan();
                } else {
                  finalTime = _customTime ?? widget.scheduledTime;
                }
                Navigator.pop(context, {
                  'status': IntakeStatus.taken,
                  'takenTime': finalTime,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.appleGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Log Intake',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedOption == id;
    final color = isSelected ? AppTheme.appleGreen : Colors.grey[100]!;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedOption = id);
        if (onTap != null) onTap();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : color,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isSelected ? color.withOpacity(0.8) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.scheduledTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.appleGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = TimezoneUtil.nowInPakistan();
      setState(() {
        _customTime = DateTime(
          widget.scheduledTime.year,
          widget.scheduledTime.month,
          widget.scheduledTime.day,
          picked.hour,
          picked.minute,
        );
        _selectedOption = 'custom';
      });
    }
  }
}
