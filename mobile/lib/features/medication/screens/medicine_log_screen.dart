import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_util.dart';
import '../../../core/widgets/modern_scaffold.dart';

class MedicineLogScreen extends StatefulWidget {
  const MedicineLogScreen({super.key});

  @override
  State<MedicineLogScreen> createState() => _MedicineLogScreenState();
}

class _MedicineLogScreenState extends State<MedicineLogScreen> {
  String? _selectedMedicineId;
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

    final filteredIntakes = _selectedMedicineId == null
        ? medicationProvider.allIntakes
        : medicationProvider.allIntakes
            .where((i) => i.medicineId == _selectedMedicineId)
            .toList();

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(medicationProvider),
          Expanded(
            child: medicationProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedDates.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 80.h),
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

  Widget _buildFilters(MedicationProvider provider) {
    final medicines = provider.medicines;
    
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: medicines.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final medicine = isAll ? null : medicines[index - 1];
          final isSelected = isAll 
              ? _selectedMedicineId == null 
              : _selectedMedicineId == medicine?.id;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(
                isAll ? 'medication.history.allMedicines'.tr() : medicine!.name,
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedMedicineId = isAll ? null : medicine?.id;
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTimeOfDayTag(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'medication.timeOfDay.morning'.tr();
    if (hour >= 12 && hour < 17) return 'medication.timeOfDay.afternoon'.tr();
    return 'medication.timeOfDay.evening'.tr();
  }

  Widget _buildDateGroup(DateTime date, List<MedicineIntake> intakes) {
    final now = TimezoneUtil.nowInPakistan();
    final isToday = now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
    
    final dateStr = isToday ? 'Today' : DateFormat('EEE, MMM d').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Text(
            dateStr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...intakes.map((log) => _buildLogCard(log)).toList(),
      ],
    );
  }

  Widget _buildLogCard(MedicineIntake log) {
    final isTaken = log.status == IntakeStatus.taken;
    final color = isTaken ? AppTheme.getSuccessColor(context) : Theme.of(context).colorScheme.error;
    final icon = isTaken ? Icons.check_circle : Icons.error_outline;
    
    final timeStr = DateFormat('hh:mm a').format(log.scheduledTime);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          log.medicineName ?? 'Medicine',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Scheduled for $timeStr (${_getTimeOfDayTag(log.scheduledTime)})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'medication.history.status.${log.status.name}'.tr().toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
            if (log.takenTime != null)
              Text(
                DateFormat('hh:mm a').format(log.takenTime!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
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
            Icons.history_edu,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          SizedBox(height: 16.h),
          Text(
            'medication.history.noHistoryForFilter'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
