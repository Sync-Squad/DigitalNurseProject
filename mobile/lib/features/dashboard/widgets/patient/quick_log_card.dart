import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/care_context_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_surface_theme.dart';
import '../../../../core/models/medicine_model.dart';

class QuickLogCard extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onLogged;

  const QuickLogCard({
    super.key,
    required this.reminder,
    required this.onLogged,
  });

  @override
  State<QuickLogCard> createState() => _QuickLogCardState();
}

class _QuickLogCardState extends State<QuickLogCard> with SingleTickerProviderStateMixin {
  bool _isLogging = false;

  Future<void> _handleStatus(BuildContext context, IntakeStatus status) async {
    if (_isLogging) return;

    setState(() => _isLogging = true);
    HapticFeedback.mediumImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicationProvider>();
      final careContext = context.read<CareContextProvider>();
      
      final user = authProvider.currentUser;
      if (user == null) return;

      final String? medicineId = (widget.reminder['medicine'] as MedicineModel?)?.id;
      final DateTime? scheduledTime = widget.reminder['reminderTime'] as DateTime?;
      
      if (medicineId == null || scheduledTime == null) return;
      
      // Perform optimistic update callback
      widget.onLogged();

      final success = await medProvider.logIntake(
        medicineId: medicineId,
        scheduledTime: scheduledTime,
        status: status,
        userId: user.id,
        elderUserId: careContext.selectedElderId,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update medication status.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicine = widget.reminder['medicine'] as MedicineModel?;
    final DateTime? time = widget.reminder['reminderTime'] as DateTime?;

    if (medicine == null || time == null) return const SizedBox.shrink();
    
    final String name = medicine.name;
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Container(
      width: 130.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF9), // Ultra-light teal glaze
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ModernSurfaceTheme.primaryTeal.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // Colored Accent Bar (Thinner)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3.w,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ModernSurfaceTheme.primaryTeal,
                      ModernSurfaceTheme.primaryTeal.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 8.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: ModernSurfaceTheme.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_filled, size: 8.sp, color: ModernSurfaceTheme.primaryTeal),
                        SizedBox(width: 2.w),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            color: ModernSurfaceTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: ModernSurfaceTheme.deepTeal,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(),
                  if (_isLogging)
                    Center(
                      child: SizedBox(
                        height: 16.sp,
                        width: 16.sp,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: ModernSurfaceTheme.primaryTeal),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ActionButton(
                          icon: Icons.close_rounded,
                          color: Colors.redAccent,
                          onTap: () => _handleStatus(context, IntakeStatus.missed),
                        ),
                        _ActionButton(
                          icon: Icons.check_rounded,
                          color: AppTheme.appleGreen,
                          onTap: () => _handleStatus(context, IntakeStatus.taken),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: color,
        ),
      ),
    );
  }
}
