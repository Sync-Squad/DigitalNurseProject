import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/utils/timezone_util.dart';
import '../widgets/intake_log_bottom_sheet.dart';
import '../widgets/missed_remarks_bottom_sheet.dart';

class MedicineDetailScreen extends StatefulWidget {
  final String medicineId;
  final DateTime? selectedDate;
  final String? reminderTime;

  const MedicineDetailScreen({
    super.key,
    required this.medicineId,
    this.selectedDate,
    this.reminderTime,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  List<MedicineIntake>? _intakeHistory;
  IntakeStatus? _loggingStatus; // Track which status is being logged
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadIntakeHistory();
  }

  Future<void> _loadIntakeHistory() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      final user = authProvider.currentUser;

      String? elderUserId;
      if (user?.role == UserRole.caregiver) {
        final careContext = context.read<CareContextProvider>();
        await careContext.ensureLoaded();
        elderUserId = careContext.selectedElderId;
      }

      final history = await medicationProvider.getIntakeHistory(
        widget.medicineId,
        elderUserId: elderUserId,
      );
      if (mounted) {
        setState(() {
          _intakeHistory = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _intakeHistory = [];
        });
      }
    }
  }

  MedicineIntake? _hasExistingIntakeForTime(DateTime scheduledTime) {
    if (_intakeHistory == null || _intakeHistory!.isEmpty) {
      return null;
    }

    final targetDate = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    );
    final targetHour = scheduledTime.hour;
    final targetMinute = scheduledTime.minute;

    for (final intake in _intakeHistory!) {
      final intakeDate = DateTime(
        intake.scheduledTime.year,
        intake.scheduledTime.month,
        intake.scheduledTime.day,
      );
      final intakeHour = intake.scheduledTime.hour;
      final intakeMinute = intake.scheduledTime.minute;

      if (intakeDate.isAtSameMomentAs(targetDate) &&
          intakeHour == targetHour &&
          intakeMinute == targetMinute &&
          (intake.status == IntakeStatus.taken ||
              intake.status == IntakeStatus.missed)) {
        return intake;
      }
    }
    return null;
  }

  Future<void> _handleLogIntake(IntakeStatus status) async {
    if (_loggingStatus != null) return;

    setState(() {
      _loggingStatus = status;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      final user = authProvider.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('common.errors.notAuthenticated'.tr()),
              backgroundColor: AppTheme.getErrorColor(context),
            ),
          );
        }
        return;
      }

      medicationProvider.clearError();

      final medicine = medicationProvider.medicines.firstWhere(
        (m) => m.id == widget.medicineId,
      );

      final targetDate = widget.selectedDate ?? DateTime.now();
      final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

      String? timeToUse = widget.reminderTime;
      if (timeToUse == null && medicine.reminderTimes.isNotEmpty) {
        timeToUse = medicine.reminderTimes.first;
      }

      DateTime? scheduledTime;
      if (timeToUse != null) {
        final parts = timeToUse.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            scheduledTime = DateTime(targetDay.year, targetDay.month, targetDay.day, hour, minute);
          }
        }
      }
      scheduledTime ??= TimezoneUtil.nowInPakistan();

      Map<String, dynamic>? result;
      if (status == IntakeStatus.taken) {
        result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => IntakeLogBottomSheet(
            medicine: medicine,
            scheduledTime: scheduledTime!,
          ),
        );
      } else if (status == IntakeStatus.missed) {
        result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MissedRemarksBottomSheet(
            medicine: medicine,
          ),
        );
      }

      if (result == null) {
        if (mounted) setState(() => _loggingStatus = null);
        return;
      }

      String? elderUserId;
      if (user.role == UserRole.caregiver) {
        final careContext = context.read<CareContextProvider>();
        await careContext.ensureLoaded();
        elderUserId = careContext.selectedElderId ?? medicine.userId;
      }

      final success = await medicationProvider.logIntake(
        medicineId: widget.medicineId,
        scheduledTime: scheduledTime,
        status: result['status'],
        takenTime: result['takenTime'],
        note: result['note'],
        userId: user.id,
        elderUserId: elderUserId,
      );

      if (mounted) {
        if (success) {
          final finalStatus = result['status'] as IntakeStatus;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                finalStatus == IntakeStatus.taken
                    ? 'medication.detail.marked'.tr(namedArgs: {'status': 'medication.status.taken'.tr()})
                    : 'medication.detail.marked'.tr(namedArgs: {'status': 'medication.status.missed'.tr()}),
              ),
              backgroundColor: finalStatus == IntakeStatus.taken
                  ? AppTheme.getSuccessColor(context)
                  : AppTheme.getWarningColor(context),
            ),
          );
          _loadIntakeHistory();
        } else {
          final errorMessage = medicationProvider.error ?? 'medication.detail.logFail'.tr();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.getErrorColor(context),
            ),
          );
          medicationProvider.clearError();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loggingStatus = null;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('medication.detail.deleteTitle'.tr()),
        content: Text('medication.detail.deleteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        if (user == null) return;

        String? elderUserId;
        if (user.role == UserRole.caregiver) {
          final careContext = context.read<CareContextProvider>();
          await careContext.ensureLoaded();
          elderUserId = careContext.selectedElderId;
        }

        final success = await context.read<MedicationProvider>().deleteMedicine(
          widget.medicineId,
          user.id,
          elderUserId: elderUserId,
        );

        if (mounted) {
          if (success) {
            context.pop();
          } else {
            final errorMessage = context.read<MedicationProvider>().error ?? 'medication.detail.deleteFail'.tr();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppTheme.getErrorColor(context),
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final medicine = medicationProvider.medicines.firstWhere(
      (m) => m.id == widget.medicineId,
      orElse: () => MedicineModel(
        id: widget.medicineId,
        name: 'Medicine',
        dosage: '',
        frequency: MedicineFrequency.daily,
        startDate: DateTime.now(),
        reminderTimes: [],
        userId: '',
      ),
    );

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          medicine.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/medicine/add', extra: medicine);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          _isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  onPressed: _handleDelete,
                  icon: Icon(Icons.delete_outline, color: AppTheme.getErrorColor(context)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MedicineInfoCard(
              medicine: medicine,
              reminderTime: widget.reminderTime,
            ),
            SizedBox(height: 20.h),
            _QuickActions(
              onLog: _handleLogIntake,
              loggingStatus: _loggingStatus,
              currentStatus: widget.selectedDate != null || widget.reminderTime != null 
                ? _hasExistingIntakeForTime(
                    () {
                      final targetDate = widget.selectedDate ?? TimezoneUtil.nowInPakistan();
                      final timeToUse = widget.reminderTime ?? (medicine.reminderTimes.isNotEmpty ? medicine.reminderTimes.first : "08:00");
                      final parts = timeToUse.split(':');
                      final hour = int.tryParse(parts[0]) ?? 8;
                      final minute = int.tryParse(parts[1]) ?? 0;
                      return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
                    }()
                  )?.status
                : null,
            ),
            SizedBox(height: 24.h),
            Text(
              'medication.detail.intakeHistory'.tr(),
              style: ModernSurfaceTheme.sectionTitleStyle(context),
            ),
            SizedBox(height: 12.h),
            if (_intakeHistory == null)
              const Center(child: CircularProgressIndicator())
            else if (_intakeHistory!.isEmpty)
              Container(
                decoration: ModernSurfaceTheme.glassCard(context),
                padding: EdgeInsets.all(24.w),
                child: Center(
                  child: Text(
                    'medication.detail.noHistory'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ModernSurfaceTheme.deepTeal.withOpacity(0.7),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _intakeHistory!
                    .map(
                      (intake) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          decoration: ModernSurfaceTheme.glassCard(
                            context,
                            accent: intake.status == IntakeStatus.taken
                                ? AppTheme.getSuccessColor(context)
                                : intake.status == IntakeStatus.missed
                                ? AppTheme.getErrorColor(context)
                                : ModernSurfaceTheme.accentBlue,
                          ),
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              Icon(
                                intake.status == IntakeStatus.taken
                                    ? Icons.check_circle_outline
                                    : intake.status == IntakeStatus.missed
                                    ? Icons.cancel_outlined
                                    : Icons.circle_outlined,
                                color: intake.status == IntakeStatus.taken
                                    ? AppTheme.getSuccessColor(context)
                                    : intake.status == IntakeStatus.missed
                                    ? AppTheme.getErrorColor(context)
                                    : ModernSurfaceTheme.deepTeal,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _statusName(intake.status),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: ModernSurfaceTheme.deepTeal,
                                          ),
                                    ),
                                    Text(
                                      TimezoneUtil.formatInPakistan(
                                        intake.status == IntakeStatus.taken && intake.takenTime != null
                                          ? intake.takenTime!
                                          : intake.scheduledTime,
                                        format: 'MMM d, yyyy • h:mm a',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ModernSurfaceTheme.deepTeal
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.w,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ModernSurfaceTheme.deepTeal.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ModernSurfaceTheme.deepTeal,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicineInfoCard extends StatelessWidget {
  final MedicineModel medicine;
  final String? reminderTime;

  const _MedicineInfoCard({required this.medicine, this.reminderTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: ModernSurfaceTheme.primaryTeal,
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: ModernSurfaceTheme.iconBadge(
                  context,
                  ModernSurfaceTheme.primaryTeal,
                ),
                child: const Icon(Icons.medication, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ModernSurfaceTheme.deepTeal,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      medicine.dosage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ModernSurfaceTheme.deepTeal.withOpacity(0.7),
                      ),
                    ),
                    if (reminderTime != null || medicine.priority != MedicinePriority.medium) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          if (reminderTime != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: ModernSurfaceTheme.primaryTeal.withOpacity(
                                  0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: ModernSurfaceTheme.primaryTeal.withOpacity(
                                    0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getTimeOfDayLabel(reminderTime!),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: ModernSurfaceTheme.primaryTeal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                    ),
                              ),
                            ),
                          if (reminderTime != null) SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: medicine.priority == MedicinePriority.high 
                                  ? Colors.red.withOpacity(0.15) 
                                  : medicine.priority == MedicinePriority.medium
                                  ? Colors.amber.withOpacity(0.15)
                                  : Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: medicine.priority == MedicinePriority.high 
                                    ? Colors.red.withOpacity(0.3) 
                                    : medicine.priority == MedicinePriority.medium
                                    ? Colors.amber.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (medicine.priority == MedicinePriority.high)
                                  Icon(Icons.warning_rounded, size: 12.sp, color: Colors.red),
                                if (medicine.priority == MedicinePriority.high)
                                  SizedBox(width: 4.w),
                                Text(
                                  'medication.priority.${medicine.priority.name.toLowerCase()}'.tr(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: medicine.priority == MedicinePriority.high 
                                            ? Colors.red 
                                            : medicine.priority == MedicinePriority.medium
                                            ? Colors.amber[700]
                                            : Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.sp,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const Divider(),
          SizedBox(height: 20.h),
          _InfoRow(
            label: 'medication.add.steps.frequency'.tr(),
            value: _frequencyName(medicine.frequency),
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            label: 'medication.add.steps.startDate'.tr(),
            value: DateFormat('MMM d, yyyy').format(medicine.startDate),
          ),
          if (medicine.endDate != null) ...[
            SizedBox(height: 8.h),
            _InfoRow(
              label: 'medication.add.steps.endDate'.tr(),
              value: DateFormat('MMM d, yyyy').format(medicine.endDate!),
            ),
          ],
          SizedBox(height: 8.h),
          _InfoRow(
            label: 'medication.add.steps.reminders'.tr(),
            value: medicine.reminderTimes.join(', '),
          ),
          if (medicine.notes != null && medicine.notes!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _InfoRow(label: 'medication.add.steps.notes'.tr(), value: medicine.notes!),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Future<void> Function(IntakeStatus status) onLog;
  final IntakeStatus? loggingStatus;
  final IntakeStatus? currentStatus;

  const _QuickActions({
    required this.onLog, 
    this.loggingStatus,
    this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: EdgeInsets.all(20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            label: 'medication.status.missed'.tr(),
            icon: Icons.close,
            color: AppTheme.getErrorColor(context),
            isLoading: loggingStatus == IntakeStatus.missed,
            isSelected: currentStatus == IntakeStatus.missed,
            onTap: () => onLog(IntakeStatus.missed),
          ),
          _ActionButton(
            label: 'medication.status.taken'.tr(),
            icon: Icons.check,
            color: AppTheme.getSuccessColor(context),
            isLoading: loggingStatus == IntakeStatus.taken,
            isSelected: currentStatus == IntakeStatus.taken,
            onTap: () => onLog(IntakeStatus.taken),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isSelected ? Colors.white : color,
                    ),
                  )
                : Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: 24,
                  ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? color : ModernSurfaceTheme.deepTeal.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}

String _frequencyName(MedicineFrequency freq) {
  switch (freq) {
    case MedicineFrequency.daily:
      return 'Once Daily';
    case MedicineFrequency.twiceDaily:
      return 'Twice Daily';
    case MedicineFrequency.thriceDaily:
      return 'Three Times Daily';
    case MedicineFrequency.weekly:
      return 'Weekly';
    case MedicineFrequency.asNeeded:
      return 'As Needed';
    case MedicineFrequency.periodic:
      return 'Periodic';
    case MedicineFrequency.beforeMeal:
      return 'Before Meal';
    case MedicineFrequency.afterMeal:
      return 'After Meal';
  }
}

String _statusName(IntakeStatus status) {
  switch (status) {
    case IntakeStatus.taken:
      return 'Taken';
    case IntakeStatus.missed:
      return 'Missed';
    case IntakeStatus.skipped:
      return 'Skipped';
    case IntakeStatus.pending:
      return 'Pending';
    case IntakeStatus.snoozed:
      return 'Snoozed';
  }
}

String _getTimeOfDayLabel(String timeStr) {
  final parts = timeStr.split(':');
  if (parts.length != 2) return timeStr;

  final hour = int.tryParse(parts[0]);
  if (hour == null) return timeStr;

  if (hour >= 5 && hour < 12) {
    return 'medication.timeOfDay.morning'.tr();
  } else if (hour >= 12 && hour < 17) {
    return 'medication.timeOfDay.afternoon'.tr();
  } else {
    return 'medication.timeOfDay.evening'.tr();
  }
}
