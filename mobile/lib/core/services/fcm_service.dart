import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_model.dart';
import '../models/medicine_model.dart';
import '../../firebase_options.dart';
import '../utils/timezone_util.dart';

/// Callback type for navigating to alarm screen
typedef AlarmNavigationCallback = void Function(String? payload);

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  /// Callback to navigate to alarm screen when notification is tapped
  AlarmNavigationCallback? onAlarmTap;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;
  bool? _exactAlarmPermission;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  bool? get exactAlarmPermission => _exactAlarmPermission;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already done
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize timezone data
      tz.initializeTimeZones();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission for notifications
      await _requestPermission();

      // Get FCM token
      await _getToken();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('FCM Service initialized successfully');
    } catch (e) {
      print('Error initializing FCM Service: $e');
      // Don't rethrow to prevent app crashes
      // Just mark as not initialized so it can be retried
      _isInitialized = false;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Setup notification channels for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _setupNotificationChannels();
    }
  }

  /// Setup Android notification channels
  Future<void> _setupNotificationChannels() async {
    const medicationChannel = AndroidNotificationChannel(
      'medication_reminders',
      'Medication Reminders',
      description: 'Notifications for regular medication reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const alarmChannel = AndroidNotificationChannel(
      'medication_alarms',
      'Medication Alarms',
      description: 'Full-screen alarms for high-priority medications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const healthChannel = AndroidNotificationChannel(
      'health_alerts',
      'Health Alerts',
      description: 'Notifications for health monitoring and vitals',
      importance: Importance.high,
      playSound: true,
    );

    const generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications and updates',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(medicationChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(alarmChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(healthChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    if (kIsWeb) return;

    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        throw Exception('Notification permission denied');
      }
    } else if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final granted = await androidPlugin?.requestNotificationsPermission();
      if (granted != true) {
        throw Exception('Notification permission denied');
      }

      // Request exact alarm permission for Android 12+
      try {
        final canScheduleExact = await androidPlugin
            ?.canScheduleExactNotifications();
        _exactAlarmPermission = canScheduleExact;

        if (canScheduleExact == false) {
          print('Requesting exact alarm permission...');
          final exactAlarmGranted = await androidPlugin
              ?.requestExactAlarmsPermission();
          _exactAlarmPermission = exactAlarmGranted ?? false;

          if (exactAlarmGranted == true) {
            print('✅ Exact alarm permission granted!');
          } else {
            print(
              '⚠️ Exact alarm permission denied - using inexact scheduling',
            );
            print('⚠️ Notifications may be delayed by 5-15 minutes');
          }
        } else {
          print('✅ Exact alarm permission already granted');
        }
      } catch (e) {
        print('Could not request exact alarm permission: $e');
        _exactAlarmPermission = false;
      }
    }
  }

  /// Get FCM token
  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        // TODO: Send new token to backend
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message (when app is terminated)
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }

  /// Handle message opened app (background/terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');

    // TODO: Navigate to specific screen based on message data
    final data = message.data;
    if (data.containsKey('type')) {
      _handleNotificationNavigation(data['type'], data);
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    if (response.payload != null) {
      final payloadStr = response.payload!;
      // Check if this is a medicine reminder
      if (payloadStr.contains('medicine_reminder') ||
          payloadStr.contains('medicineId')) {
        
        // Check if it's high priority
        bool isHighPriority = false;
        try {
          final data = jsonDecode(payloadStr);
          isHighPriority = data['priority'] == 'high';
        } catch (e) {
          print('Error decoding notification payload: $e');
        }
        
        if (isHighPriority) {
          // Navigate to alarm screen for high priority
          onAlarmTap?.call(response.payload);
        } else {
          // Navigate to medicine detail or generic screen for low/medium
          // In current implementation, we still might want to show alarm or detail
          // but for now let's stick to the instruction of alarm for high priority.
          onAlarmTap?.call(response.payload); 
        }
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] ?? 'general';
    final isMedicineReminder =
        type == 'medicine_reminder' || type == 'missed_dose';

    final androidDetails = AndroidNotificationDetails(
      _getChannelId(message.data),
      _getChannelName(message.data),
      channelDescription: _getChannelDescription(message.data),
      importance: message.data['priority'] == 'high' ? Importance.max : Importance.high,
      priority: message.data['priority'] == 'high' ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
      // Enable sound and vibration for medicine reminders
      playSound: true,
      enableVibration: true,
      vibrationPattern: (isMedicineReminder && !kIsWeb)
          ? Int64List.fromList([0, 250, 250, 250])
          : null,
      channelShowBadge: true,
      autoCancel: true,
      fullScreenIntent: message.data['priority'] == 'high',
      category: message.data['priority'] == 'high' ? AndroidNotificationCategory.alarm : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Get channel ID based on message data
  String _getChannelId(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    switch (type) {
      case 'medicine_reminder':
      case 'missed_dose':
      case 'NotificationType.medicineReminder':
      case 'NotificationType.missedDose':
        return data['priority'] == 'high' ? 'medication_alarms' : 'medication_reminders';
      case 'health_alert':
      case 'vitals_reminder':
      case 'NotificationType.healthAlert':
        return 'health_alerts';
      default:
        return 'general_notifications';
    }
  }

  /// Get channel name based on message data
  String _getChannelName(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    switch (type) {
      case 'medicine_reminder':
      case 'missed_dose':
      case 'NotificationType.medicineReminder':
      case 'NotificationType.missedDose':
        return 'Medication Reminders';
      case 'health_alert':
      case 'vitals_reminder':
      case 'NotificationType.healthAlert':
        return 'Health Alerts';
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description based on message data
  String _getChannelDescription(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    switch (type) {
      case 'medicine_reminder':
      case 'missed_dose':
      case 'NotificationType.medicineReminder':
      case 'NotificationType.missedDose':
        return 'Notifications for medication reminders and missed doses';
      case 'health_alert':
      case 'vitals_reminder':
      case 'NotificationType.healthAlert':
        return 'Notifications for health monitoring and vitals';
      default:
        return 'General app notifications and updates';
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(String type, Map<String, dynamic> data) {
    // TODO: Implement navigation logic based on notification type
    switch (type) {
      case 'medicine_reminder':
        // Navigate to medicine detail screen
        break;
      case 'health_alert':
        // Navigate to health monitoring screen
        break;
      case 'diet_reminder':
        // Navigate to diet/exercise screen
        break;
      default:
        // Navigate to dashboard
        break;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Schedule local notification
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationType type = NotificationType.general,
    MedicinePriority priority = MedicinePriority.medium,
  }) async {
    try {
      // Check if FCM service is initialized
      if (!_isInitialized) {
        print('FCM service not initialized, attempting to initialize...');
        try {
          await initialize();
        } catch (e) {
          print('Failed to initialize FCM service: $e');
          return; // Exit gracefully instead of crashing
        }
      }

      // Only schedule if the date is in the future
      if (scheduledDate.isBefore(TimezoneUtil.nowInPakistan())) {
        print('Skipping notification - scheduled time is in the past');
        return;
      }

      final channelId = _getChannelId({'type': type.toString()});
      final channelName = _getChannelName({'type': type.toString()});
      final channelDescription = _getChannelDescription({
        'type': type.toString(),
      });

      final isHighPriority = priority == MedicinePriority.high;
      final isMedicineReminder = type == NotificationType.medicineReminder;

      final androidDetails = AndroidNotificationDetails(
        isHighPriority ? 'medication_alarms' : channelId,
        isHighPriority ? 'Medication Alarms' : channelName,
        channelDescription: isHighPriority ? 'Full-screen alarms for high-priority medications' : channelDescription,
        importance: isHighPriority ? Importance.max : Importance.high,
        priority: isHighPriority ? Priority.max : Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        vibrationPattern: (isMedicineReminder && !kIsWeb)
            ? Int64List.fromList([0, 500, 250, 500, 250, 500])
            : null,
        channelShowBadge: true,
        autoCancel: !isHighPriority, 
        ticker: isMedicineReminder ? 'Medicine Reminder' : null,
        fullScreenIntent: isHighPriority,
        category: isHighPriority ? AndroidNotificationCategory.alarm : null,
        visibility: NotificationVisibility.public,
        ongoing: isHighPriority,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Try exact scheduling first, fallback to inexact if permission denied
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        // print(
        //   '✅ Notification #$id scheduled successfully for "$title" at $scheduledDate (exact)',
        // );
      } catch (e) {
        if (e.toString().contains('exact_alarms_not_permitted')) {
          print('⚠️ Exact alarm permission denied, using inexact scheduling');
          print('⚠️ Notification #$id may be delayed by 5-15 minutes');
          _exactAlarmPermission = false;

          // Fallback to inexact scheduling
          await _localNotifications.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledDate, tz.local),
            details,
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          // print('✅ Notification #$id scheduled with inexact timing for "$title"');
        } else {
          print('❌ Error scheduling notification #$id: $e');
          // Don't rethrow to prevent app crashes
        }
      }
    } catch (e) {
      print('Failed to schedule notification: $e');
      // Don't rethrow to prevent breaking medicine saving
    }
  }

  /// Cancel scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Check if exact alarm notifications can be scheduled
  Future<bool?> canScheduleExactNotifications() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final canScheduleExact = await androidPlugin
            ?.canScheduleExactNotifications();
        _exactAlarmPermission = canScheduleExact;
        return canScheduleExact;
      } catch (e) {
        print('Error checking exact alarm permission: $e');
        return false;
      }
    }
    return true; // iOS doesn't need this permission
  }

  /// Request exact alarm permission manually
  Future<bool> requestExactAlarmPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        final canScheduleExact = await androidPlugin
            ?.canScheduleExactNotifications();
        _exactAlarmPermission = canScheduleExact;

        if (canScheduleExact == false) {
          print('Requesting exact alarm permission...');
          final granted = await androidPlugin?.requestExactAlarmsPermission();
          _exactAlarmPermission = granted ?? false;

          if (granted == true) {
            print('✅ Exact alarm permission granted!');
            return true;
          } else {
            print('⚠️ Exact alarm permission denied');
            print('⚠️ Notifications may be delayed by 5-15 minutes');
            return false;
          }
        } else {
          print('✅ Exact alarm permission already granted');
          return true;
        }
      } catch (e) {
        print('Error requesting exact alarm permission: $e');
        _exactAlarmPermission = false;
        return false;
      }
    }
    return true; // iOS doesn't need this permission
  }

  /// Get diagnostic information about notification setup
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final info = <String, dynamic>{
      'isInitialized': _isInitialized,
      'hasFcmToken': _fcmToken != null,
      'exactAlarmPermission': _exactAlarmPermission,
    };

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final canScheduleExact = await androidPlugin
            ?.canScheduleExactNotifications();
        info['canScheduleExact'] = canScheduleExact;
        info['exactAlarmPermission'] = canScheduleExact;

        // Check full-screen intent permission
        final fullScreenStatus = await checkFullScreenIntentPermission();
        info['fullScreenIntentPermission'] = fullScreenStatus;
      } catch (e) {
        info['permissionCheckError'] = e.toString();
      }
    }

    return info;
  }

  /// Check if full-screen intent permission is granted (Android 11+)
  Future<bool> checkFullScreenIntentPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      // On Android 11+ (API 30+), we need to check this permission
      final status = await Permission.systemAlertWindow.status;
      print('Full-screen intent permission status: $status');
      return status.isGranted;
    } catch (e) {
      print('Error checking full-screen intent permission: $e');
      // If we can't check, assume it's not granted
      return false;
    }
  }

  /// Request full-screen intent permission
  /// Returns true if permission is granted or user was directed to settings
  Future<bool> requestFullScreenIntentPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final status = await Permission.systemAlertWindow.status;

      if (status.isGranted) {
        print('Full-screen intent permission already granted');
        return true;
      }

      // Request the permission - this will open settings on Android 11+
      final result = await Permission.systemAlertWindow.request();
      print('Full-screen intent permission request result: $result');

      return result.isGranted;
    } catch (e) {
      print('Error requesting full-screen intent permission: $e');
      return false;
    }
  }

  /// Open app settings for user to enable permissions manually
  Future<bool> openPermissionSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}
