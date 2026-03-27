import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../utils/timezone_util.dart';
import '../models/medicine_model.dart';
import '../models/notification_model.dart';

/// A simple utility to trigger a delayed notification for testing
/// Run this from a button in a debug screen or similar.
class NotificationDebugTool {
  static Future<void> triggerDelayedNotification(String medicineName) async {
    final fcmService = FCMService();
    
    // Ensure initialized
    if (!fcmService.isInitialized) {
      await fcmService.initialize();
    }

    final scheduledDate = TimezoneUtil.nowInPakistan().add(const Duration(seconds: 10));
    
    print('📅 Scheduling debug notification for $scheduledDate');
    
    await fcmService.scheduleLocalNotification(
      id: 88888,
      title: 'Debug Alarm: $medicineName',
      body: 'Time to take $medicineName (Testing background alert)',
      scheduledDate: scheduledDate,
      payload: '{"medicineId": "test_id", "medicineName": "$medicineName", "dosage": "1 pill", "type": "medicine_reminder", "priority": "high"}',
      type: NotificationType.medicineReminder,
      priority: MedicinePriority.high,
    );
  }
}
