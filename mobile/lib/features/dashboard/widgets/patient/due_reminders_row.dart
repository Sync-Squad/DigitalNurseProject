import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/utils/timezone_util.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../../../core/models/medicine_model.dart';
import 'quick_log_card.dart';

class DueRemindersRow extends StatefulWidget {
  const DueRemindersRow({super.key});

  @override
  State<DueRemindersRow> createState() => _DueRemindersRowState();
}

class _DueRemindersRowState extends State<DueRemindersRow> {
  late ScrollController _scrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 72.w) / 2; // (Screen - 64w padding - 8w gap) / 2
    
    final page = (_scrollController.offset / (cardWidth + 8.w)).round();
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final dueRemindersList = medProvider.dueReminders;
    
    final dueReminders = [...dueRemindersList];
    
    // Sort: High Priority first, then by time
    dueReminders.sort((a, b) {
      final medA = a['medicine'] as MedicineModel;
      final medB = b['medicine'] as MedicineModel;
      final timeA = a['reminderTime'] as DateTime;
      final timeB = b['reminderTime'] as DateTime;

      if (medA.priority == MedicinePriority.high && medB.priority != MedicinePriority.high) return -1;
      if (medB.priority == MedicinePriority.high && medA.priority != MedicinePriority.high) return 1;
      return timeA.compareTo(timeB);
    });

    if (medProvider.upcomingReminders.isEmpty) return const SizedBox.shrink();
    if (dueReminders.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    // contentWidth = screen - dashboardPadding(16*2) - rowPadding(16*2) = screen - 64
    // We want 2 cards with a gap of 8. (cardWidth * 2) + 8 = contentWidth
    final double cardWidth = (screenWidth - 72.w) / 2; 

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4CC7BB).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20.r),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'medication.dueNow'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 15.sp,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${dueReminders.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF071D1C),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 98.h,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: dueReminders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final reminder = dueReminders[index];
                final medicine = reminder['medicine'] as MedicineModel;
                final scheduled = reminder['reminderTime'] as DateTime;
                final scheduledUtc = scheduled.toUtc();
                final String id = "${medicine.id}_${scheduledUtc.year}_${scheduledUtc.month}_${scheduledUtc.day}_${scheduledUtc.hour}_${scheduledUtc.minute}";

                return SizedBox(
                  width: cardWidth,
                  child: QuickLogCard(
                    reminder: reminder,
                    onLogged: (status) {
                      medProvider.markReminderActioned(id, status);
                    },
                  ),
                );
              },
            ),
          ),
          if (dueReminders.length > 2) ...[
            SizedBox(height: 8.h),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  dueReminders.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    width: index == _currentPage ? 14.w : 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: index == _currentPage ? 1.0 : 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
