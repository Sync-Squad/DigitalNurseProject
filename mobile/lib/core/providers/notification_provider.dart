import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // Cache tracking for "Smart Loading"
  DateTime? _lastFetchTime;


  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Load notifications
  Future<void> loadNotifications() async {
    // Smart Loading Check: Skip if data is fresh (within 5 seconds)
    final now = DateTime.now();
    if (_lastFetchTime != null && 
        now.difference(_lastFetchTime!) < const Duration(seconds: 5)) {
      print('⏭️ [NOTIFICATION] Smart Loading: Skipping redundant fetch (data is fresh)');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications();
      _unreadCount = await _notificationService.getUnreadCount();
      _lastFetchTime = DateTime.now();

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Schedule notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required NotificationType type,
    DateTime? scheduledTime,
    String? actionData,
  }) async {
    final notification = await _notificationService.scheduleNotification(
      title: title,
      body: body,
      type: type,
      scheduledTime: scheduledTime,
      actionData: actionData,
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  // Mark as read
  Future<void> markAsRead(String notificationId, {String? elderUserId}) async {
    await _notificationService.markAsRead(notificationId, elderUserId: elderUserId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount--;
      notifyListeners();
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead();
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
    );
    await _notificationService.deleteNotification(notificationId);
    _notifications.removeWhere((n) => n.id == notificationId);
    if (!notification.isRead) {
      _unreadCount--;
    }
    notifyListeners();
  }

  // Initialize FCM
  Future<void> initializeFCM() async {
    await _notificationService.initializeFCM();
  }

  // Get FCM token
  String? getFCMToken() {
    return _notificationService.getFCMToken();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _notificationService.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _notificationService.unsubscribeFromTopic(topic);
  }

  // Initialize mock data (now loads real data)
  Future<void> initializeMockData() async {
    await loadNotifications();
  }

  // Request exact alarm permission
  Future<bool> requestExactAlarmPermission() async {
    return await _notificationService.requestExactAlarmPermission();
  }

  // Get diagnostic information
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    return await _notificationService.getDiagnosticInfo();
  }

  // Check full-screen intent permission
  Future<bool> checkFullScreenIntentPermission() async {
    return await _fcmService.checkFullScreenIntentPermission();
  }

  // Request full-screen intent permission
  Future<bool> requestFullScreenIntentPermission() async {
    return await _fcmService.requestFullScreenIntentPermission();
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _fcmService.cancelAllNotifications();
  }
}
