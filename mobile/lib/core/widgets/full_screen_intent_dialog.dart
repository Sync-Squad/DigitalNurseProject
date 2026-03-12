import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/fcm_service.dart';

/// Dialog to prompt users to enable full-screen intent permission
/// for automatic alarm screen display
class FullScreenIntentDialog extends StatelessWidget {
  const FullScreenIntentDialog({super.key});

  /// Show the dialog if permission is not granted
  static Future<void> showIfNeeded(BuildContext context) async {
    final fcmService = FCMService();
    final hasPermission = await fcmService.checkFullScreenIntentPermission();

    if (!hasPermission && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const FullScreenIntentDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.alarm,
              color: const Color(0xFF4FC3F7),
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          const Expanded(
            child: Text(
              'Enable Medicine Alarms',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To show medicine reminder alarms automatically (like a wake-up alarm), please enable "Display over other apps" permission.',
            style: TextStyle(fontSize: 14.sp, height: 1.5),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'This allows the alarm screen to appear when your phone is locked.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Later', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: () async {
            // Open app settings
            await openAppSettings();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}

/// A simpler inline banner for settings screen
class FullScreenIntentBanner extends StatefulWidget {
  const FullScreenIntentBanner({super.key});

  @override
  State<FullScreenIntentBanner> createState() => _FullScreenIntentBannerState();
}

class _FullScreenIntentBannerState extends State<FullScreenIntentBanner> {
  bool _hasPermission = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final fcmService = FCMService();
    final hasPermission = await fcmService.checkFullScreenIntentPermission();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _hasPermission) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Alarm Permission Needed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Enable "Display over other apps" to show medicine reminders automatically like an alarm.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                await Future.delayed(const Duration(seconds: 1));
                _checkPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text('Enable Now'),
            ),
          ),
        ],
      ),
    );
  }
}
