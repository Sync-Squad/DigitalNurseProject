import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/models/notification_model.dart';

class MedicineAlarmScreen extends StatefulWidget {
  final String? medicineId;
  final String? medicineName;
  final String? dosage;
  final String? payload;

  const MedicineAlarmScreen({
    super.key,
    this.medicineId,
    this.medicineName,
    this.dosage,
    this.payload,
  });

  @override
  State<MedicineAlarmScreen> createState() => _MedicineAlarmScreenState();
}

class _MedicineAlarmScreenState extends State<MedicineAlarmScreen>
    with SingleTickerProviderStateMixin {
  final AlarmService _alarmService = AlarmService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _autoCloseTimer;
  String _currentTime = '';
  Timer? _clockTimer;

  String? _medicineId;
  String _medicineName = 'Medicine';
  String _dosage = '';

  @override
  void initState() {
    super.initState();

    // Parse payload or use direct parameters
    _parsePayload();

    // COMMENTED OUT: Alarm ringing functionality temporarily disabled
    // This was causing the app to work when screen is locked and appear on lock screen
    // Start the alarm sound
    // _alarmService.startAlarm();

    // Setup pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Update clock every second
    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );

    // Auto-close after 5 minutes if no action
    _autoCloseTimer = Timer(const Duration(minutes: 5), () {
      _dismissAlarm();
    });

    // Keep screen on and hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _parsePayload() {
    if (widget.payload != null) {
      try {
        final data = jsonDecode(widget.payload!);
        _medicineId = data['medicineId'];
        _medicineName =
            data['medicineName'] ?? widget.medicineName ?? 'Medicine';
        _dosage = data['dosage'] ?? widget.dosage ?? '';
      } catch (e) {
        print('Error parsing payload: $e');
        _medicineName = widget.medicineName ?? 'Medicine';
        _dosage = widget.dosage ?? '';
        _medicineId = widget.medicineId;
      }
    } else {
      _medicineName = widget.medicineName ?? 'Medicine';
      _dosage = widget.dosage ?? '';
      _medicineId = widget.medicineId;
    }
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm').format(DateTime.now());
    });
  }

  Future<void> _takeMedicine() async {
    await _alarmService.stopAlarm();

    // Log the intake if we have the medicine ID
    if (_medicineId != null) {
      try {
        final authProvider = context.read<AuthProvider>();
        final medicationProvider = context.read<MedicationProvider>();
        final user = authProvider.currentUser;

        if (user != null) {
          await medicationProvider.logIntake(
            medicineId: _medicineId!,
            scheduledTime: DateTime.now(),
            status: IntakeStatus.taken,
            userId: user.id,
          );
        }
      } catch (e) {
        print('Error logging intake: $e');
      }
    }

    _dismissAlarm();
  }

  Future<void> _snoozeAlarm() async {
    await _alarmService.snoozeAlarm();

    // Reschedule notification for 5 minutes from now
    if (_medicineId != null) {
      try {
        final fcmService = FCMService();
        final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
        await fcmService.scheduleLocalNotification(
          id: '${_medicineId}_snooze_${snoozeTime.millisecondsSinceEpoch}'
              .hashCode,
          title: 'Medicine Reminder (Snoozed)',
          body: 'Time to take $_medicineName $_dosage',
          scheduledDate: snoozeTime,
          payload:
              '{"medicineId": "$_medicineId", "medicineName": "$_medicineName", "dosage": "$_dosage", "type": "medicine_reminder"}',
          type: NotificationType.medicineReminder,
        );
        print('Snoozed alarm rescheduled for $snoozeTime');
      } catch (e) {
        print('Error rescheduling snooze: $e');
      }
    }

    // Show snooze confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm snoozed for 5 minutes'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    _dismissAlarm();
  }

  void _dismissAlarm() {
    _autoCloseTimer?.cancel();
    _clockTimer?.cancel();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      // Navigate back or to home
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoCloseTimer?.cancel();
    _clockTimer?.cancel();
    _alarmService.stopAlarm();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Deep indigo
              Color(0xFF0D1B2A), // Dark blue-black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Current time
              Text(
                _currentTime,
                style: TextStyle(
                  fontSize: 72.sp,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),

              SizedBox(height: 8.h),

              // "Medicine Reminder" label
              Text(
                'MEDICINE REMINDER',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 3,
                ),
              ),

              const Spacer(flex: 1),

              // Pulsing alarm indicator
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 160.w,
                      height: 160.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF4FC3F7).withOpacity(0.8),
                            const Color(0xFF29B6F6).withOpacity(0.4),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4FC3F7).withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4FC3F7),
                          ),
                          child: Icon(
                            Icons.medication_rounded,
                            size: 50.w,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),

              // Medicine name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _medicineName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              if (_dosage.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  _dosage,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],

              SizedBox(height: 16.h),

              // "Time to take your medicine" message
              Text(
                'Time to take your medicine',
                style: TextStyle(fontSize: 16.sp, color: Colors.white54),
              ),

              const Spacer(flex: 2),

              // Action buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Row(
                  children: [
                    // Snooze button
                    Expanded(
                      child: _AlarmButton(
                        onPressed: _snoozeAlarm,
                        icon: Icons.snooze_rounded,
                        label: 'Snooze',
                        sublabel: '5 min',
                        color: const Color(0xFF5C6BC0),
                      ),
                    ),

                    SizedBox(width: 20.w),

                    // Take medicine button
                    Expanded(
                      child: _AlarmButton(
                        onPressed: _takeMedicine,
                        icon: Icons.check_circle_rounded,
                        label: 'Take',
                        sublabel: 'Medicine',
                        color: const Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 48.h),

              // Dismiss text
              GestureDetector(
                onTap: _dismissAlarm,
                child: Text(
                  'Dismiss',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white38,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _AlarmButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 48.w, color: color),
              SizedBox(height: 12.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(fontSize: 14.sp, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
