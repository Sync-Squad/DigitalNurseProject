import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_util.dart';
import '../../../core/widgets/modern_scaffold.dart';

class MedicationHistoryScreen extends StatefulWidget {
  const MedicationHistoryScreen({super.key});

  @override
  State<MedicationHistoryScreen> createState() => _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen> {
  String? _selectedMedicineId;
  int _selectedDays = 7; // Default to 7 days
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadData();
      _initialized = true;
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<MedicationProvider>();
    final careContext = context.read<CareContextProvider>();
    final authProvider = context.read<AuthProvider>();
    
    final elderUserId = careContext.selectedElderId;
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      if (provider.medicines.isEmpty) {
        await provider.loadMedicines(userId, elderUserId: elderUserId);
      }
      await provider.loadAllIntakeHistory(elderUserId: elderUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Filter by medicine and date range
    final now = TimezoneUtil.nowInPakistan();
    final filterDate = now.subtract(Duration(days: _selectedDays));

    final filteredIntakes = medicationProvider.allIntakes.where((i) {
      final matchesMedicine = _selectedMedicineId == null || i.medicineId == _selectedMedicineId;
      final matchesDate = i.scheduledTime.isAfter(filterDate);
      return matchesMedicine && matchesDate;
    }).toList();

    // Stats for summary: Treat both Missed and Pending as non-compliant
    int takenCount = 0;
    int missedCount = 0;
    int pendingCount = 0;
    for (final intake in filteredIntakes) {
      if (intake.status == IntakeStatus.taken) {
        takenCount++;
      } else if (intake.status == IntakeStatus.missed) {
        missedCount++;
      } else if (intake.status == IntakeStatus.pending) {
        pendingCount++;
      }
    }
    
    final totalPlanned = takenCount + missedCount + pendingCount;
    final compliance = totalPlanned == 0 ? 100.0 : (takenCount / totalPlanned) * 100;

    // Group by date
    final groupedIntakes = <DateTime, List<MedicineIntake>>{};
    for (final intake in filteredIntakes) {
      final date = DateTime(
        intake.scheduledTime.year,
        intake.scheduledTime.month,
        intake.scheduledTime.day,
      );
      groupedIntakes.putIfAbsent(date, () => []).add(intake);
    }

    final sortedDates = groupedIntakes.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ModernScaffold(
      appBar: AppBar(
        title: Text(
          'medication.history.title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryCard(compliance, takenCount, missedCount, pendingCount),
          _buildFilters(medicationProvider),
          Expanded(
            child: medicationProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedDates.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 40.h),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final intakes = groupedIntakes[date]!;
                          return _buildDateGroup(date, intakes);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double compliance, int taken, int missed, int pending) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: ModernSurfaceTheme.heroDecoration(context),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adherence Rate',
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${compliance.toInt()}%',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Icon(
                  compliance >= 80 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: Colors.white,
                  size: 36.r,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Taken', taken.toString(), Icons.check_circle_rounded, AppTheme.appleGreen),
              _buildStatItem('Missed', missed.toString(), Icons.cancel_rounded, Colors.redAccent),
              _buildStatItem('Pending', pending.toString(), Icons.watch_later_rounded, ModernSurfaceTheme.accentYellow),
            ],
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Last $_selectedDays Days Analysis',
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.4),
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16.r),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(MedicationProvider provider) {
    final medicines = provider.medicines;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Medicine Dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedMedicineId,
                isExpanded: true,
                dropdownColor: colorScheme.surface,
                hint: Text('All Medications', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Medications'),
                  ),
                  ...medicines.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name),
                  )),
                ],
                onChanged: (val) => setState(() => _selectedMedicineId = val),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Days Period Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPeriodTab('7 Days', 7),
              _buildPeriodTab('14 Days', 14),
              _buildPeriodTab('30 Days', 30),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, int days) {
    final isSelected = _selectedDays == days;
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = days),
      child: Container(
        width: 105.w,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.appleGreen : colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : colorScheme.onSurface.withOpacity(0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateGroup(DateTime date, List<MedicineIntake> intakes) {
    final now = TimezoneUtil.nowInPakistan();
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
    
    final dateStr = isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16.h, bottom: 8.h, left: 4.w),
          child: Text(
            dateStr,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...intakes.map((log) => _buildLogCard(log)).toList(),
      ],
    );
  }

  Widget _buildLogCard(MedicineIntake log) {
    final isTaken = log.status == IntakeStatus.taken;
    final isMissed = log.status == IntakeStatus.missed;
    final isPending = log.status == IntakeStatus.pending;
    
    final colorScheme = Theme.of(context).colorScheme;
    final color = isTaken 
        ? AppTheme.appleGreen 
        : (isMissed ? Colors.redAccent : ModernSurfaceTheme.accentYellow);
    final icon = isTaken ? Icons.check_circle_rounded : (isMissed ? Icons.cancel_rounded : Icons.pending_actions_rounded);
    
    final timeStr = DateFormat('hh:mm a').format(log.scheduledTime);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24.r),
        ),
        title: Text(
          log.medicineName ?? 'Medicine',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Scheduled for $timeStr',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            log.status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 80.r,
            color: Colors.white.withOpacity(0.1),
          ),
          SizedBox(height: 16.h),
          Text(
            'No history found for this period',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
