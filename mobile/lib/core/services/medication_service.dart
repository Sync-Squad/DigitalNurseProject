import '../models/medicine_model.dart';
import '../models/notification_model.dart';
import '../mappers/medication_mapper.dart';
import 'api_service.dart';
import 'fcm_service.dart';

class MedicationService {
  final ApiService _apiService = ApiService();
  final FCMService _fcmService = FCMService();

  void _log(String message) {
    print('🔍 [MEDICATION] $message');
  }

  // Helper method to check if error is unauthorized (user logging out)
  bool _isUnauthorizedError(dynamic error) {
    final errorMessage = error.toString();
    return errorMessage.contains('Unauthorized') ||
        errorMessage.contains('401');
  }

  // Helper method to check if error is forbidden (caregiver not assigned to elder)
  bool _isForbiddenError(dynamic error) {
    final errorMessage = error.toString();
    return errorMessage.contains('Forbidden') ||
        errorMessage.contains('403') ||
        errorMessage.contains('not assigned to the requested elder');
  }

  // Get all medicines for a user
  Future<List<MedicineModel>> getMedicines(
    String userId, {
    String? elderUserId,
  }) async {
    _log('📋 Fetching medications for user: $userId');
    try {
      final response = await _apiService.get(
        '/medications',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final medicines = data
            .map(
              (json) => MedicationMapper.fromApiResponse(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json),
              ),
            )
            .toList();
        _log('✅ Fetched ${medicines.length} medications');
        return medicines;
      } else {
        _log('❌ Failed to fetch medications: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch medications: ${response.statusMessage}',
        );
      }
    } catch (e) {
      // Handle Forbidden errors gracefully (caregiver not assigned to elder)
      if (_isForbiddenError(e)) {
        _log(
          '⚠️ Forbidden error during medications fetch (caregiver may not have access to this elder)',
        );
        return []; // Return empty list instead of throwing
      }
      _log('❌ Error fetching medications: $e');
      throw Exception(e.toString());
    }
  }

  // Add new medicine
  Future<MedicineModel> addMedicine(MedicineModel medicine) async {
    _log('➕ Adding medication: ${medicine.name}');
    try {
      final requestData = MedicationMapper.toApiRequest(
        medicine,
        elderUserId: medicine.userId,
      );
      final response = await _apiService.post(
        '/medications',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final addedMedicine = MedicationMapper.fromApiResponse(response.data);
        _log('✅ Medication added successfully: ${addedMedicine.name}');

        // Schedule notifications for medicine reminders (with error handling)
        try {
          await _scheduleMedicineReminders(addedMedicine);
        } catch (e) {
          _log('⚠️ Warning: Failed to schedule medicine reminders: $e');
          // Don't fail the entire operation if notification scheduling fails
        }

        return addedMedicine;
      } else {
        _log('❌ Failed to add medication: ${response.statusMessage}');
        throw Exception('Failed to add medication: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error adding medication: $e');
      throw Exception(e.toString());
    }
  }

  // Update medicine
  Future<MedicineModel> updateMedicine(MedicineModel medicine) async {
    _log('✏️ Updating medication: ${medicine.name}');
    try {
      final requestData = MedicationMapper.toApiRequest(
        medicine,
        elderUserId: medicine.userId,
      );
      final response = await _apiService.patch(
        '/medications/${medicine.id}',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final updatedMedicine = MedicationMapper.fromApiResponse(response.data);
        _log('✅ Medication updated successfully: ${updatedMedicine.name}');

        // Reschedule notifications for updated medicine (with error handling)
        try {
          await _scheduleMedicineReminders(updatedMedicine);
        } catch (e) {
          _log('⚠️ Warning: Failed to reschedule medicine reminders: $e');
        }

        return updatedMedicine;
      } else {
        _log('❌ Failed to update medication: ${response.statusMessage}');
        throw Exception(
          'Failed to update medication: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error updating medication: $e');
      throw Exception(e.toString());
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String medicineId, {String? elderUserId}) async {
    _log('🗑️ Deleting medication: $medicineId');
    try {
      final response = await _apiService.delete(
        '/medications/$medicineId',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        _log('✅ Medication deleted successfully');

        // Cancel scheduled notifications for deleted medicine
        try {
          await _fcmService.cancelNotification(medicineId.hashCode);
        } catch (e) {
          _log('⚠️ Warning: Failed to cancel notifications: $e');
        }
      } else {
        _log('❌ Failed to delete medication: ${response.statusMessage}');
        throw Exception(
          'Failed to delete medication: ${response.statusMessage}',
        );
      }
    } catch (e) {
      // Handle Forbidden errors gracefully (caregiver not assigned to elder)
      if (_isForbiddenError(e)) {
        _log(
          '⚠️ Forbidden error during medication deletion (caregiver may not have access to this elder)',
        );
        return; // Complete successfully instead of throwing
      }
      _log('❌ Error deleting medication: $e');
      throw Exception(e.toString());
    }
  }

  // Get medicine by ID
  Future<MedicineModel?> getMedicineById(
    String medicineId, {
    String? elderUserId,
  }) async {
    _log('🔍 Fetching medication by ID: $medicineId');
    try {
      final response = await _apiService.get(
        '/medications/$medicineId',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final medicine = MedicationMapper.fromApiResponse(response.data);
        _log('✅ Medication fetched: ${medicine.name}');
        return medicine;
      } else {
        _log('❌ Medication not found: $medicineId');
        return null;
      }
    } catch (e) {
      // Handle Forbidden errors gracefully (caregiver not assigned to elder)
      if (_isForbiddenError(e)) {
        _log(
          '⚠️ Forbidden error during medication fetch (caregiver may not have access to this elder)',
        );
        return null; // Return null instead of throwing
      }
      _log('❌ Error fetching medication: $e');
      return null;
    }
  }

  // Log medicine intake
  Future<MedicineIntake> logIntake({
    required String medicineId,
    required DateTime scheduledTime,
    required IntakeStatus status,
    String? elderUserId,
  }) async {
    _log(
      '📝 Logging intake for medication: $medicineId, status: $status, elderUserId: $elderUserId',
    );
    try {
      final intake = MedicineIntake(
        id: '', // Will be set by backend
        medicineId: medicineId,
        scheduledTime: scheduledTime,
        takenTime: status == IntakeStatus.taken ? DateTime.now() : null,
        status: status,
      );

      final requestData = MedicationMapper.intakeToApiRequest(
        intake,
        elderUserId: elderUserId,
      );

      _log('📤 Sending request to: /medications/$medicineId/intakes');
      _log('📤 Request data: $requestData');
      _log('📤 Scheduled time (local): ${intake.scheduledTime}');
      _log('📤 Scheduled time (UTC): ${intake.scheduledTime.toUtc()}');
      _log(
        '📤 Scheduled time (ISO): ${intake.scheduledTime.toUtc().toIso8601String()}',
      );
      _log(
        '📤 Query params: ${elderUserId != null ? {'elderUserId': elderUserId} : null}',
      );

      final response = await _apiService.post(
        '/medications/$medicineId/intakes',
        data: requestData,
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      _log('📥 Response status: ${response.statusCode}');
      _log('📥 Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final loggedIntake = MedicationMapper.intakeFromApiResponse(
          response.data,
        );
        _log('✅ Intake logged successfully');
        return loggedIntake;
      } else {
        _log(
          '❌ Failed to log intake: ${response.statusCode} - ${response.statusMessage}',
        );
        _log('❌ Response data: ${response.data}');
        final errorMessage = response.data is Map
            ? (response.data['message'] ??
                  response.data['error'] ??
                  response.statusMessage)
            : response.statusMessage;
        throw Exception('Failed to log intake: $errorMessage');
      }
    } catch (e, stackTrace) {
      _log('❌ Exception caught: $e');
      _log('❌ Stack trace: $stackTrace');

      // Handle Forbidden errors with clearer message (caregiver not assigned to elder)
      if (_isForbiddenError(e)) {
        _log(
          '⚠️ Forbidden error during intake logging (caregiver may not have access to this elder)',
        );
        throw Exception(
          'You do not have permission to log intake for this patient.',
        );
      }

      // Extract a cleaner error message
      String errorMessage = 'An error occurred. Please try again.';
      final errorString = e.toString();

      if (errorString.contains('SocketException') ||
          errorString.contains('Failed host lookup')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorString.contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (errorString.contains('Exception: ')) {
        errorMessage = errorString.replaceAll('Exception: ', '');
      } else if (errorString.isNotEmpty) {
        errorMessage = errorString;
      }

      _log('❌ Throwing error: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  // Get intake history for a medicine
  Future<List<MedicineIntake>> getIntakeHistory(
    String medicineId, {
    String? elderUserId,
  }) async {
    _log('📜 Fetching intake history for medication: $medicineId');
    try {
      final response = await _apiService.get(
        '/medications/$medicineId/intakes',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final intakes =
            data
                .map(
                  (json) => MedicationMapper.intakeFromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList()
              ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
        _log('✅ Fetched ${intakes.length} intake records');
        return intakes;
      } else {
        _log('❌ Failed to fetch intake history: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch intake history: ${response.statusMessage}',
        );
      }
    } catch (e) {
      // Handle Unauthorized errors gracefully (user might be logging out)
      if (_isUnauthorizedError(e)) {
        _log(
          '⚠️ Unauthorized error during intake history fetch (user may be logging out)',
        );
        return []; // Return empty list instead of throwing
      }
      // Handle Forbidden errors gracefully (caregiver not assigned to elder)
      if (_isForbiddenError(e)) {
        _log(
          '⚠️ Forbidden error during intake history fetch (caregiver may not have access to this elder)',
        );
        return []; // Return empty list instead of throwing
      }
      _log('❌ Error fetching intake history: $e');
      throw Exception(e.toString());
    }
  }

  // Get upcoming reminders
  Future<List<Map<String, dynamic>>> getUpcomingReminders(
    String userId, {
    String? elderUserId,
  }) async {
    _log('⏰ Fetching upcoming reminders for user: $userId');
    try {
      final response = await _apiService.get(
        '/medications/upcoming',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final reminders = data.map((item) {
          final map = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);
          return {
            'medicine': MedicationMapper.fromApiResponse(map['medicine'] ?? {}),
            'reminderTime': DateTime.parse(
              map['reminderTime']?.toString() ??
                  DateTime.now().toIso8601String(),
            ),
            'status': map['status']?.toString() ?? 'pending',
          };
        }).toList();
        _log('✅ Fetched ${reminders.length} upcoming reminders');
        return reminders;
      } else {
        _log('❌ Failed to fetch upcoming reminders: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch upcoming reminders: ${response.statusMessage}',
        );
      }
    } catch (e) {
      // Handle Forbidden errors gracefully (caregiver not assigned to elder)
      if (_isForbiddenError(e)) {
        _log(
          '⚠️ Forbidden error during upcoming reminders fetch (caregiver may not have access to this elder)',
        );
        return []; // Return empty list instead of throwing
      }
      _log('❌ Error fetching upcoming reminders: $e');
      throw Exception(e.toString());
    }
  }

  // Get adherence percentage
  Future<double> getAdherencePercentage(
    String userId, {
    int days = 7,
    String? elderUserId,
  }) async {
    _log(
      '📊 Calculating overall adherence percentage for user: $userId (last $days days)',
    );

    try {
      final response = await _apiService.get(
        '/medications/adherence',
        queryParameters: {
          'days': days.toString(),
          if (elderUserId != null) 'elderUserId': elderUserId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final rate = (data['adherenceRate'] ?? 1.0) as double;
        final percentage = rate * 100;
        _log('✅ Overall adherence: ${percentage.toStringAsFixed(1)}%');
        return percentage;
      }
    } catch (e) {
      _log('⚠️ Warning: Failed to get overall adherence: $e');
    }

    return 100.0;
  }

  // Get adherence streak (consecutive days with 100% adherence)
  Future<int> getAdherenceStreak(String userId, {String? elderUserId}) async {
    _log('🔥 Calculating overall adherence streak for user: $userId');

    try {
      final response = await _apiService.get(
        '/medications/adherence/streak',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final streak = (data['streak'] ?? 0) as int;
        _log('✅ Overall adherence streak: $streak days');
        return streak;
      }
    } catch (e) {
      _log('⚠️ Warning: Failed to get overall streak: $e');
    }

    return 0;
  }

  // Test immediate notification (for debugging)
  Future<Map<String, dynamic>> testImmediateNotification(
    String medicineName,
  ) async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'errors': <String>[],
    };

    try {
      _log('🧪 Testing immediate notification for $medicineName');

      // Check if FCM service is initialized
      if (!_fcmService.isInitialized) {
        _log('FCM service not initialized, attempting to initialize...');
        try {
          await _fcmService.initialize();
          if (!_fcmService.isInitialized) {
            result['errors'].add('Failed to initialize FCM service');
            result['message'] = 'FCM service initialization failed';
            return result;
          }
        } catch (e) {
          _log('Failed to initialize FCM service: $e');
          result['errors'].add('FCM initialization error: $e');
          result['message'] = 'Failed to initialize FCM service';
          return result;
        }
      }

      // Check exact alarm permission
      final canScheduleExact = await _fcmService
          .canScheduleExactNotifications();
      if (canScheduleExact == false) {
        result['errors'].add(
          'Exact alarm permission not granted - notification may be delayed',
        );
      }

      final testTime = DateTime.now().add(const Duration(seconds: 10));
      await _fcmService.scheduleLocalNotification(
        id: 99999, // Use a unique ID for testing
        title: 'Test Medicine Reminder',
        body: 'Time to take $medicineName - This is a test notification',
        scheduledDate: testTime,
        payload:
            '{"type": "test_notification", "medicineName": "$medicineName"}',
        type: NotificationType.medicineReminder,
      );

      _log(
        '✅ Test notification scheduled for 10 seconds from now (${testTime.toString()})',
      );
      result['success'] = true;
      result['message'] = 'Test notification scheduled for 10 seconds from now';
      if (canScheduleExact == false) {
        result['message'] += ' (may be delayed due to inexact scheduling)';
      }
    } catch (e) {
      _log('❌ Failed to schedule test notification: $e');
      result['errors'].add('Scheduling error: $e');
      result['message'] = 'Failed to schedule test notification: $e';
    }

    return result;
  }

  // Reschedule all medicine reminders (for app start)
  Future<int> rescheduleAllMedicineReminders(
    List<MedicineModel> medicines,
  ) async {
    _log('🔄 Rescheduling reminders for ${medicines.length} medicines');
    int scheduledCount = 0;

    try {
      // Check if FCM service is initialized
      if (!_fcmService.isInitialized) {
        _log('FCM service not initialized, attempting to initialize...');
        try {
          await _fcmService.initialize();
        } catch (e) {
          _log('Failed to initialize FCM service: $e');
          return 0;
        }
      }

      // Check exact alarm permission and warn if not available
      final canScheduleExact = await _fcmService
          .canScheduleExactNotifications();
      if (canScheduleExact == false) {
        _log(
          '⚠️ Warning: Exact alarm permission not granted. Notifications may be delayed.',
        );
      }

      // Cancel existing notifications for all medicines first
      for (final medicine in medicines) {
        try {
          // Cancel by medicine ID hash (approximate, but helps clean up)
          await _fcmService.cancelNotification(medicine.id.hashCode);
        } catch (e) {
          _log(
            'Warning: Failed to cancel existing notifications for ${medicine.name}: $e',
          );
        }
      }

      // Reschedule reminders for each medicine
      for (final medicine in medicines) {
        try {
          await _scheduleMedicineReminders(medicine);
          scheduledCount++;
        } catch (e) {
          _log(
            '⚠️ Warning: Failed to reschedule reminders for ${medicine.name}: $e',
          );
          // Continue with other medicines even if one fails
        }
      }

      _log(
        '✅ Rescheduled reminders for $scheduledCount/${medicines.length} medicines',
      );
      return scheduledCount;
    } catch (e) {
      _log('❌ Error rescheduling all medicine reminders: $e');
      return scheduledCount;
    }
  }

  // Schedule medicine reminder notifications
  Future<void> _scheduleMedicineReminders(MedicineModel medicine) async {
    try {
      // Check if FCM service is initialized
      if (!_fcmService.isInitialized) {
        _log('FCM service not initialized, attempting to initialize...');
        try {
          await _fcmService.initialize();
        } catch (e) {
          _log('Failed to initialize FCM service: $e');
          return;
        }
      }

      // Validate reminder times
      if (medicine.reminderTimes.isEmpty) {
        _log('Warning: No reminder times for ${medicine.name}');
        return;
      }

      final now = DateTime.now();
      int scheduledForThisMedicine = 0;

      for (int i = 0; i < 7; i++) {
        // Schedule for next 7 days
        final date = now.add(Duration(days: i));

        for (final timeStr in medicine.reminderTimes) {
          try {
            final parts = timeStr.split(':');
            if (parts.length != 2) {
              _log(
                'Warning: Invalid time format: $timeStr for ${medicine.name}',
              );
              continue;
            }

            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);

            if (hour == null ||
                minute == null ||
                hour < 0 ||
                hour > 23 ||
                minute < 0 ||
                minute > 59) {
              _log(
                'Warning: Invalid time values: $timeStr for ${medicine.name}',
              );
              continue;
            }

            final reminderTime = DateTime(
              date.year,
              date.month,
              date.day,
              hour,
              minute,
            );

            // Only schedule if the time is in the future
            if (reminderTime.isAfter(now)) {
              final notificationId =
                  '${medicine.id}_${reminderTime.millisecondsSinceEpoch}'
                      .hashCode;
              _log(
                '📅 Scheduling notification #$notificationId for ${medicine.name} at ${reminderTime.toString()}',
              );

              await _fcmService.scheduleLocalNotification(
                id: notificationId,
                title: 'Medicine Reminder',
                body: 'Time to take ${medicine.name} ${medicine.dosage}',
                scheduledDate: reminderTime,
                payload:
                    '{"medicineId": "${medicine.id}", "medicineName": "${medicine.name}", "dosage": "${medicine.dosage}", "type": "medicine_reminder"}',
                type: NotificationType.medicineReminder,
              );
              scheduledForThisMedicine++;
            } else {
              _log(
                '⏭️ Skipping notification for ${medicine.name} - time ${reminderTime.toString()} is in the past',
              );
            }
          } catch (e) {
            _log(
              '⚠️ Warning: Failed to schedule reminder for time $timeStr: $e',
            );
            // Continue with other times even if one fails
          }
        }
      }

      _log(
        '✅ Scheduled $scheduledForThisMedicine notifications for ${medicine.name}',
      );
    } catch (e) {
      _log('❌ Error in _scheduleMedicineReminders for ${medicine.name}: $e');
      rethrow;
    }
  }

  // Verify notification setup and return diagnostic report
  Future<Map<String, dynamic>> verifyNotificationSetup() async {
    final report = <String, dynamic>{
      'fcmInitialized': false,
      'notificationPermission': false,
      'exactAlarmPermission': false,
      'canScheduleExact': false,
      'errors': <String>[],
    };

    try {
      // Check FCM initialization
      report['fcmInitialized'] = _fcmService.isInitialized;
      if (!_fcmService.isInitialized) {
        report['errors'].add('FCM service is not initialized');
      }

      // Check permissions (Android only)
      final canScheduleExact = await _fcmService
          .canScheduleExactNotifications();
      if (canScheduleExact != null) {
        report['canScheduleExact'] = canScheduleExact;
        report['exactAlarmPermission'] = canScheduleExact;

        if (!canScheduleExact) {
          report['errors'].add(
            'Exact alarm permission not granted - notifications may be delayed by 5-15 minutes',
          );
        }
      }

      // Note: Notification permission check would require platform-specific code
      // For now, we assume it's granted if FCM is initialized
      report['notificationPermission'] = _fcmService.isInitialized;
    } catch (e) {
      report['errors'].add('Error checking setup: $e');
    }

    return report;
  }

  // Get estimated count of scheduled notifications
  // Note: This is an estimate based on medicines and their reminder times
  Future<int> getEstimatedScheduledNotificationsCount() async {
    try {
      // This is a rough estimate - actual count depends on:
      // - Number of medicines
      // - Number of reminder times per medicine
      // - How many are in the future (next 7 days)
      // We can't get the actual count from the notification system easily
      return 0; // Placeholder - actual implementation would require platform-specific code
    } catch (e) {
      _log('Error estimating notification count: $e');
      return 0;
    }
  }
}
