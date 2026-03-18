import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/medicine_model.dart';

class MissedRemarksBottomSheet extends StatefulWidget {
  final MedicineModel medicine;

  const MissedRemarksBottomSheet({
    super.key,
    required this.medicine,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required MedicineModel medicine,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MissedRemarksBottomSheet(
        medicine: medicine,
      ),
    );
  }

  @override
  State<MissedRemarksBottomSheet> createState() => _MissedRemarksBottomSheetState();
}

class _MissedRemarksBottomSheetState extends State<MissedRemarksBottomSheet> {
  String? _selectedReason;
  final List<String> _reasons = [
    'Forgot',
    'Refused',
    'Sleeping',
    'Out of medicine',
    'Other',
  ];

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
            'Mark as Missed',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.red[800],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please select a reason for missing ${widget.medicine.name}.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: _reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = reason),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? Colors.red[300]! : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.red[800] : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 32.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'status': IntakeStatus.missed,
                      'note': _selectedReason,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Confirm Missed',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
