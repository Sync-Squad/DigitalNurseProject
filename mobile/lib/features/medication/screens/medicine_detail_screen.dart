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
      // Handle errors gracefully, especially during logout
      if (mounted) {
        setState(() {
          _intakeHistory = []; // Set empty list on error
        });
      }
    }
  }

  /// Checks if there's an existing intake record for the specified scheduled time
  /// Returns the existing intake if found, null otherwise
  MedicineIntake? _hasExistingIntakeForTime(DateTime scheduledTime) {
    if (_intakeHistory == null || _intakeHistory!.isEmpty) {
      return null;
    }

    // Check for existing intake with same date and time (hour, minute)
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

      // Check if same date and time, and status is taken or missed (not pending)
      if (intakeDate.year == targetDate.year &&
          intakeDate.month == targetDate.month &&
          intakeDate.day == targetDate.day &&
          intakeHour == targetHour &&
          intakeMinute == targetMinute &&
          (intake.status == IntakeStatus.taken ||
              intake.status == IntakeStatus.missed)) {
        return intake;
      }
    }

    return null;
  }

  /// Gets the time of day label (Morning, Afternoon, Evening) from a time string
  String _getTimeOfDayLabel(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;

    final hour = int.tryParse(parts[0]);
    if (hour == null) return timeStr;

    if (hour < 12) {
      return 'medication.timeOfDay.morning'.tr();
    } else if (hour < 17) {
      return 'medication.timeOfDay.afternoon'.tr();
    } else {
      return 'medication.timeOfDay.evening'.tr();
    }
  }

  Future<void> _handleLogIntake(IntakeStatus status) async {
    if (_loggingStatus != null) return; // Already logging

    print(
      '🔵 [MEDICINE_DETAIL] Starting _handleLogIntake with status: $status',
    );

    setState(() {
      _loggingStatus = status; // Track which status is being logged
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      final user = authProvider.currentUser;

      print('🔵 [MEDICINE_DETAIL] User: ${user?.id}, Role: ${user?.role}');

      if (user == null) {
        print('❌ [MEDICINE_DETAIL] User is null');
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

      // Clear any existing error in the provider to prevent it from showing on list screen
      medicationProvider.clearError();

      final medicine = medicationProvider.medicines.firstWhere(
        (m) => m.id == widget.medicineId,
      );

      print(
        '🔵 [MEDICINE_DETAIL] Medicine found: ${medicine.name}, ID: ${medicine.id}',
      );
      print('🔵 [MEDICINE_DETAIL] Selected date: ${widget.selectedDate}');
      print('🔵 [MEDICINE_DETAIL] Reminder time: ${widget.reminderTime}');

      // Use the selected date from calendar, or default to today
      final targetDate = widget.selectedDate ?? DateTime.now();
      final targetDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      print('🔵 [MEDICINE_DETAIL] Target date: $targetDay');

      // Find the scheduled time for the selected date
      // Use the specific reminder time if provided, otherwise use the first one
      DateTime? scheduledTime;

      String? timeToUse = widget.reminderTime;
      if (timeToUse == null && medicine.reminderTimes.isNotEmpty) {
        // Fallback to first reminder time if no specific time provided
        timeToUse = medicine.reminderTimes.first;
      }

      if (timeToUse != null) {
        final parts = timeToUse.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            scheduledTime = DateTime(
              targetDay.year,
              targetDay.month,
              targetDay.day,
              hour,
              minute,
            );
            print(
              '🔵 [MEDICINE_DETAIL] Using reminder time: $timeToUse for date: $targetDay',
            );
            print(
              '🔵 [MEDICINE_DETAIL] Calculated scheduledTime: $scheduledTime',
            );
            print(
              '🔵 [MEDICINE_DETAIL] Scheduled time (UTC): ${scheduledTime.toUtc()}',
            );
          }
        }
      }

      // Fallback to current time if no valid time found
      scheduledTime ??= DateTime.now();

      print('🔵 [MEDICINE_DETAIL] Final scheduled time: $scheduledTime');
      print(
        '🔵 [MEDICINE_DETAIL] Final scheduled time (UTC): ${scheduledTime.toUtc()}',
      );

      // Check for existing intake record for this specific timing
      final existingIntake = _hasExistingIntakeForTime(scheduledTime);
      if (existingIntake != null) {
        // Determine time of day label
        final timeLabel = timeToUse != null
            ? _getTimeOfDayLabel(timeToUse)
            : 'medication.detail.atThisTime'.tr();

        // Show toast message indicating duplicate
        if (mounted) {
          final statusLabel = existingIntake.status == IntakeStatus.taken
              ? 'medication.status.taken'.tr()
              : 'medication.status.missed'.tr();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'medication.detail.alreadyMarked'.tr(namedArgs: {
                  'status': statusLabel,
                  'time': timeLabel,
                }),
              ),
              backgroundColor: AppTheme.getWarningColor(context),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Clear logging status and return early
        if (mounted) {
          setState(() {
            _loggingStatus = null;
          });
        }
        return;
      }

      // Handle caregiver context - get elderUserId if user is a caregiver
      String? elderUserId;
      if (user.role == UserRole.caregiver) {
        print('🔵 [MEDICINE_DETAIL] User is caregiver, getting elderUserId');
        final careContext = context.read<CareContextProvider>();
        await careContext.ensureLoaded();
        elderUserId = careContext.selectedElderId ?? medicine.userId;
        print('🔵 [MEDICINE_DETAIL] ElderUserId: $elderUserId');
      } else {
        print('🔵 [MEDICINE_DETAIL] User is patient, elderUserId will be null');
      }

      print(
        '🔵 [MEDICINE_DETAIL] Calling logIntake with: medicineId=${widget.medicineId}, status=$status, elderUserId=$elderUserId',
      );

      final success = await medicationProvider.logIntake(
        medicineId: widget.medicineId,
        scheduledTime: scheduledTime, // Use actual scheduled time
        status: status,
        userId: user.id,
        elderUserId: elderUserId,
      );

      print('🔵 [MEDICINE_DETAIL] logIntake returned: $success');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == IntakeStatus.taken
                    ? 'medication.detail.marked'.tr(namedArgs: {'status': 'medication.status.taken'.tr()})
                    : 'medication.detail.marked'.tr(namedArgs: {'status': 'medication.status.missed'.tr()}),
              ),
              backgroundColor: status == IntakeStatus.taken
                  ? AppTheme.getSuccessColor(context)
                  : AppTheme.getWarningColor(context),
            ),
          );
          _loadIntakeHistory();
        } else {
          // If logIntake returned false, show error from provider
          final errorMessage =
              medicationProvider.error ??
              'medication.detail.logFail'.tr(); // Added logFail to en.json/ur.json below
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.getErrorColor(context),
              duration: const Duration(seconds: 4),
            ),
          );
          // Clear the error after displaying it
          medicationProvider.clearError();
        }
      }
    } catch (e, stackTrace) {
      // Catch any exceptions and display them locally
      print('❌ [MEDICINE_DETAIL] Exception in _handleLogIntake: $e');
      print('❌ [MEDICINE_DETAIL] Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'An error occurred. Please try again later.';
        final errorString = e.toString();

        if (errorString.contains('Exception: ')) {
          errorMessage = errorString.replaceAll('Exception: ', '');
        } else if (errorString.isNotEmpty) {
          errorMessage = errorString;
        }

        print('❌ [MEDICINE_DETAIL] Displaying error: $errorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.getErrorColor(context),
            duration: const Duration(seconds: 5),
          ),
        );
        // Clear provider error to prevent it from showing on list screen
        context.read<MedicationProvider>().clearError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loggingStatus = null; // Clear the logging status
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

        if (user == null) {
          return;
        }

        // Handle caregiver context - get elderUserId if user is a caregiver
        String? elderUserId;
        if (user.role == UserRole.caregiver) {
          final medicationProvider = context.read<MedicationProvider>();
          final medicine = medicationProvider.medicines.firstWhere(
            (m) => m.id == widget.medicineId,
            orElse: () => throw Exception('Medicine not found'),
          );
          final careContext = context.read<CareContextProvider>();
          await careContext.ensureLoaded();
          elderUserId = careContext.selectedElderId ?? medicine.userId;
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
            final errorMessage =
                context.read<MedicationProvider>().error ??
                'medication.detail.deleteFail'.tr();
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
            icon: Icon(
              Icons.edit_outlined,
              color: Colors.white,
            ),
          ),
          _isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _isDeleting ? null : _handleDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.getErrorColor(context),
                  ),
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
                                    ? FIcons.check
                                    : intake.status == IntakeStatus.missed
                                    ? FIcons.x
                                    : FIcons.circle,
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
                                      () {
                                        // Convert UTC time to Pakistan time for display
                                        final timeToDisplay =
                                            intake.status ==
                                                    IntakeStatus.taken &&
                                                intake.takenTime != null
                                            ? intake.takenTime!
                                            : intake.scheduledTime;

                                        // Convert UTC DateTime to Pakistan timezone
                                        final pakistanTime =
                                            TimezoneUtil.toPakistanTime(
                                              timeToDisplay,
                                            );

                                        // Create a DateTime with Pakistan time components for formatting
                                        final displayDateTime = DateTime(
                                          pakistanTime.year,
                                          pakistanTime.month,
                                          pakistanTime.day,
                                          pakistanTime.hour,
                                          pakistanTime.minute,
                                        );

                                        return DateFormat(
                                          'MMM d, yyyy • h:mm a',
                                        ).format(displayDateTime);
                                      }(),
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

  /// Gets the time of day label (Morning, Afternoon, Evening) from a time string
  String _getTimeOfDayLabel(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;

    final hour = int.tryParse(parts[0]);
    if (hour == null) return timeStr;

    if (hour < 12) {
      return 'medication.timeOfDay.morning'.tr();
    } else if (hour < 17) {
      return 'medication.timeOfDay.afternoon'.tr();
    } else {
      return 'medication.timeOfDay.evening'.tr();
    }
  }

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
                child: const Icon(FIcons.pill, color: Colors.white, size: 28),
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
                    if (reminderTime != null) ...[
                      SizedBox(height: 8.h),
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
              label: 'medication.add.steps.endDate'.tr(), // Added to en.json/ur.json if missing (I'll add it)
              value: DateFormat('MMM d, yyyy').format(medicine.endDate!),
            ),
          ],
          SizedBox(height: 8.h),
          _InfoRow(
            label: 'medication.add.steps.reminders'.tr(),
            value: medicine.reminderTimes.join(', '),
          ),
          if (medicine.notes != null) ...[
            SizedBox(height: 8.h),
            _InfoRow(label: 'medication.add.steps.notes'.tr(), value: medicine.notes!), // Added to en.json/ur.json if missing (I'll add it)
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Future<void> Function(IntakeStatus status) onLog;
  final IntakeStatus?
  loggingStatus; // Track which specific status is being logged

  const _QuickActions({required this.onLog, this.loggingStatus});

  @override
  Widget build(BuildContext context) {
    final isLoggingTaken = loggingStatus == IntakeStatus.taken;
    final isLoggingMissed = loggingStatus == IntakeStatus.missed;
    final isAnyLogging = loggingStatus != null;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isAnyLogging ? null : () => onLog(IntakeStatus.taken),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: AppTheme.appleGreen,
              foregroundColor: Colors.white,
            ),
            child: isLoggingTaken
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Mark as Taken'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton(
            onPressed: isAnyLogging ? null : () => onLog(IntakeStatus.missed),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: BorderSide(
                color: ModernSurfaceTheme.deepTeal.withOpacity(0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              foregroundColor: ModernSurfaceTheme.deepTeal,
            ),
            child: isLoggingMissed
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ModernSurfaceTheme.deepTeal,
                    ),
                  )
                : const Text('Mark as Missed'),
          ),
        ),
      ],
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
  }
}
