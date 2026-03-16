import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../utils/timezone_util.dart';
import '../theme/app_theme.dart';

class HorizontalModernCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? startDate;
  final DateTime? endDate;

  const HorizontalModernCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.startDate,
    this.endDate,
  });

  @override
  State<HorizontalModernCalendar> createState() => _HorizontalModernCalendarState();
}

class _HorizontalModernCalendarState extends State<HorizontalModernCalendar> {
  late ScrollController _scrollController;
  final double _itemWidth = 72.w;
  final double _itemPadding = 8.w;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    
    final start = widget.startDate ?? TimezoneUtil.nowInPakistan().subtract(const Duration(days: 30));
    final diff = widget.selectedDate.difference(start).inDays;
    final targetOffset = diff * (_itemWidth + _itemPadding);
    
    _scrollController.animateTo(
      (targetOffset - ScreenUtil().screenWidth / 2 + _itemWidth / 2).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(HorizontalModernCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.startDate ?? TimezoneUtil.nowInPakistan().subtract(const Duration(days: 30));
    final end = widget.endDate ?? TimezoneUtil.nowInPakistan().add(const Duration(days: 30));
    final totalDays = end.difference(start).inDays + 1;

    return SizedBox(
      height: 95.h,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemBuilder: (context, index) {
          final date = start.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
          final isToday = DateUtils.isSameDay(date, TimezoneUtil.nowInPakistan());

          return GestureDetector(
            onTap: () => widget.onDateChanged(date),
            child: Container(
              width: _itemWidth,
              margin: EdgeInsets.only(right: _itemPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.appleGreen,
                          AppTheme.appleGreen.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                border: Border.all(
                  color: isSelected 
                      ? Colors.transparent 
                      : (isToday ? AppTheme.appleGreen.withValues(alpha: 0.5) : Colors.transparent),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.appleGreen.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.appleGreen,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy').format(date),
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
