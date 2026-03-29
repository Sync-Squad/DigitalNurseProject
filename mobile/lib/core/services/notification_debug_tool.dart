import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../services/config_service.dart';
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

  /// Manually trigger a sync of AI configuration from the database
  static Future<void> syncAIConfig() async {
    print('🔍 [DEBUG] Force syncing AI configuration...');
    final configService = ConfigService();
    final result = await configService.fetchAndCacheGeminiApiKey();
    if (result != null) {
      print('✅ [DEBUG] AI Config sync successful. Key cached.');
    } else {
      print('❌ [DEBUG] AI Config sync failed. Check backend/database.');
    }
  }
}
