import 'api_service.dart';
import '../models/notification_model.dart';
import 'fcm_service.dart';
import '../utils/timezone_util.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  final FCMService _fcmService = FCMService();

  void _log(String message) {
    print('🔍 [NOTIFICATION] $message');
  }

  // Get all notifications
  Future<List<NotificationModel>> getNotifications() async {
    _log('Fetching all notifications');
    try {
      final response = await _apiService.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load notifications');
    } catch (e) {
      _log('Error fetching notifications: $e');
      rethrow;
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    _log('Fetching unread count');
    try {
      final response = await _apiService.get('/notifications/unread/count');
      if (response.statusCode == 200) {
        return response.data['count'] as int;
      }
      return 0;
    } catch (e) {
      _log('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId, {String? elderUserId}) async {
    _log('Marking notification as read: $notificationId${elderUserId != null ? ' for elder: $elderUserId' : ''}');
    try {
      await _apiService.post(
        '/notifications/$notificationId/read',
        queryParameters: elderUserId != null ? {'elderUserId': elderUserId} : null,
      );
    } catch (e) {
      _log('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    _log('Marking all notifications as read');
    try {
      await _apiService.post('/notifications/read-all');
    } catch (e) {
      _log('Error marking all as read: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _log('Deleting notification: $notificationId');
    try {
      await _apiService.delete('/notifications/$notificationId');
    } catch (e) {
      _log('Error deleting notification: $e');
      rethrow;
    }
  }

  // Schedule notification (mock/remains for backward compatibility if needed, but updated)
  Future<NotificationModel> scheduleNotification({
    required String title,
    required String body,
    required NotificationType type,
    DateTime? scheduledTime,
    String? actionData,
  }) async {
    // Usually notifications are created by backend now, but we keep this for local scheduling if used
    final notification = NotificationModel(
      id: TimezoneUtil.nowInPakistan().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: scheduledTime ?? TimezoneUtil.nowInPakistan(),
      isRead: false,
      actionData: actionData,
    );

    // Schedule local notification if scheduledTime is provided
    if (scheduledTime != null && scheduledTime.isAfter(TimezoneUtil.nowInPakistan())) {
      await _fcmService.scheduleLocalNotification(
        id: notification.hashCode,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        payload: actionData,
        type: type,
      );
    }

    return notification;
  }

  // Initialize FCM service
  Future<void> initializeFCM() async {
    await _fcmService.initialize();
  }

  // Get FCM token
  String? getFCMToken() {
    return _fcmService.fcmToken;
  }

  // Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcmService.subscribeToTopic(topic);
  }

  // Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcmService.unsubscribeFromTopic(topic);
  }

  // Request exact alarm permission
  Future<bool> requestExactAlarmPermission() async {
    return await _fcmService.requestExactAlarmPermission();
  }

  // Get diagnostic information
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    return await _fcmService.getDiagnosticInfo();
  }
}
