import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/care_context_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_util.dart';
import '../../../../core/models/medicine_model.dart';
import '../widgets/intake_log_bottom_sheet.dart';
import '../widgets/missed_remarks_bottom_sheet.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../../../core/widgets/modern_scaffold.dart';

class DailyMedicationReviewScreen extends StatefulWidget {
  const DailyMedicationReviewScreen({super.key});

  @override
  State<DailyMedicationReviewScreen> createState() => _DailyMedicationReviewScreenState();
}

class _DailyMedicationReviewScreenState extends State<DailyMedicationReviewScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final medProvider = context.read<MedicationProvider>();
      final careContext = context.read<CareContextProvider>();
      // loadAllIntakeHistory populates the _allIntakes list in the provider
      await medProvider.loadAllIntakeHistory(
        elderUserId: careContext.selectedElderId,
      );
    } catch (e) {
      debugPrint('Error loading intake history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final todayIntakes = medProvider.dailyIntakes;

    return ModernScaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Medication Review',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : todayIntakes.isEmpty
              ? _buildEmptyState()
              : _buildIntakeList(todayIntakes),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No medications logged for today',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Check back after your first dose',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeList(List<MedicineIntake> intakes) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: intakes.length,
      itemBuilder: (context, index) {
        final intake = intakes[index];
        return _IntakeReviewCard(
          intake: intake,
          onUpdate: () => _loadHistory(),
        );
      },
    );
  }
}

class _IntakeReviewCard extends StatelessWidget {
  final MedicineIntake intake;
  final VoidCallback onUpdate;

  const _IntakeReviewCard({
    required this.intake,
    required this.onUpdate,
  });

  String _getTimeOfDayTag(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'medication.timeOfDay.morning'.tr();
    if (hour >= 12 && hour < 17) return 'medication.timeOfDay.afternoon'.tr();
    return 'medication.timeOfDay.evening'.tr();
  }

  Color _getStatusColor(IntakeStatus status) {
    switch (status) {
      case IntakeStatus.taken: return const Color(0xFF1CB5A9); // Light Teal representing taken
      case IntakeStatus.missed: return Colors.red[600]!;
      case IntakeStatus.skipped: return Colors.orange[600]!;
      case IntakeStatus.snoozed: return Colors.blue[600]!;
      default: return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(IntakeStatus status) {
    switch (status) {
      case IntakeStatus.taken: return Icons.check_circle_rounded;
      case IntakeStatus.missed: return Icons.cancel_rounded;
      case IntakeStatus.skipped: return Icons.skip_next_rounded;
      case IntakeStatus.snoozed: return Icons.snooze_rounded;
      default: return Icons.pending_rounded;
    }
  }

  String _getStatusText(IntakeStatus status) {
    switch (status) {
      case IntakeStatus.taken: 
        final timeStr = intake.takenTime != null 
            ? TimezoneUtil.formatInPakistan(intake.takenTime!, format: 'h:mm a')
            : 'taken';
        return 'Taken at $timeStr';
      case IntakeStatus.missed: return 'Missed${intake.note != null && intake.note!.isNotEmpty ? ' (${intake.note})' : ''}';
      case IntakeStatus.skipped: return 'Skipped';
      case IntakeStatus.snoozed: return 'Snoozed';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicineName = intake.medicineName ?? 'Medicine';
    final scheduledTimeStr = TimezoneUtil.formatInPakistan(intake.scheduledTime, format: 'h:mm a');
    
    final statusColor = _getStatusColor(intake.status);
    final statusIcon = _getStatusIcon(intake.status);
    final statusText = _getStatusText(intake.status);
    
    final showWarning = intake.status == IntakeStatus.taken && 
        intake.takenTime != null && 
        intake.takenTime!.difference(intake.scheduledTime).inMinutes.abs() > 30;

    final primaryTextColor = const Color(0xFF1A1A1A);
    final secondaryTextColor = const Color(0xFF4A4A4A);
    final warningColor = Colors.orange[700]!;
    final timeOfDayTag = _getTimeOfDayTag(intake.scheduledTime);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(18.w),
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: statusColor,
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: ModernSurfaceTheme.iconBadge(
                  context,
                  statusColor.withOpacity(0.2),
                ).copyWith(color: statusColor.withOpacity(0.15)),
                child: Icon(statusIcon, color: statusColor, size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medicineName,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(color: Colors.grey[300]!, width: 0.5),
                          ),
                          child: Text(
                            timeOfDayTag,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Scheduled for $scheduledTimeStr',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildEditActions(context),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (showWarning) ...[
                SizedBox(width: 8.w),
                Icon(Icons.warning_amber_rounded, color: warningColor, size: 14),
                SizedBox(width: 4.w),
                Text(
                  'Late intake',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              if (intake.status == IntakeStatus.pending || intake.status == IntakeStatus.snoozed) ...[
                _buildQuickAction(
                  context,
                  icon: Icons.close_rounded,
                  color: Colors.redAccent,
                  onTap: () => _handleQuickAction(context, IntakeStatus.missed),
                ),
                SizedBox(width: 12.w),
                _buildQuickAction(
                  context,
                  icon: Icons.check_rounded,
                  color: AppTheme.appleGreen,
                  onTap: () => _handleQuickAction(context, IntakeStatus.taken),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, size: 18.sp, color: color),
      ),
    );
  }

  Widget _buildEditActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: const Color(0xFF1A1A1A).withOpacity(0.5)),
      onSelected: (value) => _handleAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'taken',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.appleGreen, size: 20),
              SizedBox(width: 8),
              Text('Mark Taken'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'missed',
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Mark Missed'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleQuickAction(BuildContext context, IntakeStatus status) async {
    final medProvider = context.read<MedicationProvider>();
    final authProvider = context.read<AuthProvider>();
    final careContext = context.read<CareContextProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    // Find the medicine model for this intake
    final medicine = medProvider.medicines.firstWhere(
      (m) => m.id == intake.medicineId,
      orElse: () => MedicineModel(
        id: intake.medicineId,
        name: intake.medicineName ?? 'Medicine',
        dosage: '',
        frequency: MedicineFrequency.daily,
        startDate: DateTime.now(),
        reminderTimes: [],
        userId: user.id,
      ),
    );

    Map<String, dynamic>? result;
    if (status == IntakeStatus.taken) {
      result = await IntakeLogBottomSheet.show(
        context,
        medicine: medicine,
        scheduledTime: intake.scheduledTime,
      );
    } else {
      result = await MissedRemarksBottomSheet.show(
        context,
        medicine: medicine,
      );
    }

    if (result != null) {
      final success = await medProvider.logIntake(
        medicineId: intake.medicineId,
        scheduledTime: intake.scheduledTime,
        status: result['status'],
        takenTime: result['takenTime'],
        note: result['note'],
        skipReasonCode: result['note'], // Pass the same reason to skipReasonCode for missed/forgot
        userId: user.id,
        elderUserId: careContext.selectedElderId,
      );

      if (success) {
        onUpdate();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Medication updated successfully'),
              backgroundColor: const Color(0xFF1CB5A9),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  void _handleAction(BuildContext context, String value) {
    if (value == 'taken') {
      _handleQuickAction(context, IntakeStatus.taken);
    } else if (value == 'missed') {
      _handleQuickAction(context, IntakeStatus.missed);
    }
  }
}
