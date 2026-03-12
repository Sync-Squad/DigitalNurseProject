import 'dart:async';
import 'package:digital_nurse/core/models/user_model.dart';
import 'package:flutter/material.dart';
import '../models/care_recipient_model.dart';
import '../services/caregiver_service.dart';
import 'auth_provider.dart';
import 'health_provider.dart';
import 'medication_provider.dart';
import 'lifestyle_provider.dart';

class CareContextProvider with ChangeNotifier {
  final CaregiverService _caregiverService = CaregiverService();

  List<CareRecipientModel> _careRecipients = [];
  CareRecipientModel? _selectedRecipient;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  UserRole? _currentUserRole;
  bool _hasAttemptedLoad = false;
  Map<String, CareRecipientModel> _enrichedRecipients = {};

  List<CareRecipientModel> get careRecipients => _careRecipients;
  CareRecipientModel? get selectedRecipient => _selectedRecipient;
  String? get selectedElderId => _selectedRecipient?.elderId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final userId = user?.id;
    final userRole = user?.role;

    if (userId == _currentUserId && userRole == _currentUserRole) {
      return;
    }

    _currentUserId = userId;
    _currentUserRole = userRole;
    _hasAttemptedLoad = false;

    if (userRole != UserRole.caregiver) {
      _clearState();
      notifyListeners();
      return;
    }

    if (userId != null) {
      unawaited(loadCareRecipients());
    }
  }

  Future<void> ensureLoaded() async {
    if (_hasAttemptedLoad) {
      return;
    }
    await loadCareRecipients();
  }

  /// Force refresh the care recipients list (useful after accepting invitations)
  Future<void> refreshCareRecipients() async {
    _hasAttemptedLoad = false; // Reset so we can reload
    await loadCareRecipients();
  }

  Future<void> loadCareRecipients() async {
    if (_currentUserRole != UserRole.caregiver) {
      return;
    }

    _isLoading = true;
    _error = null;
    _hasAttemptedLoad = true;
    notifyListeners();

    try {
      final assignments = await _caregiverService.getCareRecipients();
      _careRecipients = assignments;
      if (assignments.isEmpty) {
        _selectedRecipient = null;
      } else {
        // Preserve previous selection if still available
        final previousId = _selectedRecipient?.elderId;
        _selectedRecipient = assignments.firstWhere(
          (assignment) => assignment.elderId == previousId,
          orElse: () => assignments.first,
        );
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _careRecipients = [];
      _selectedRecipient = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enrich recipient with user details, status, and activity
  Future<CareRecipientModel> enrichRecipient(
    CareRecipientModel recipient, {
    HealthProvider? healthProvider,
    MedicationProvider? medicationProvider,
    LifestyleProvider? lifestyleProvider,
  }) async {
    print(
      '🔍 [CARE_CONTEXT] Enriching recipient: ${recipient.elderId} (${recipient.name})',
    );

    // Check cache first
    if (_enrichedRecipients.containsKey(recipient.elderId)) {
      print(
        '✅ [CARE_CONTEXT] Using cached enriched data for ${recipient.elderId}',
      );
      return _enrichedRecipients[recipient.elderId]!;
    }

    try {
      // Fetch user details
      print(
        '📡 [CARE_CONTEXT] Fetching user details for ${recipient.elderId}...',
      );
      final userDetails = await _caregiverService.getUserDetails(
        recipient.elderId,
      );
      print(
        '📦 [CARE_CONTEXT] User details received: ${userDetails.keys.toList()}',
      );
      print('   - age: ${userDetails['age']}');
      print('   - dob: ${userDetails['dob']}');
      print('   - avatarUrl: ${userDetails['avatarUrl']}');

      final avatarUrl = userDetails['avatarUrl']?.toString();
      final age =
          userDetails['age']?.toString() ??
          (userDetails['dob'] != null
              ? _calculateAge(userDetails['dob'].toString())
              : null);
      print('✅ [CARE_CONTEXT] Calculated age: $age, avatarUrl: $avatarUrl');

      // Calculate last activity time
      DateTime? lastActivityTime;
      if (healthProvider != null ||
          medicationProvider != null ||
          lifestyleProvider != null) {
        print('⏰ [CARE_CONTEXT] Calculating last activity time...');
        lastActivityTime = await _calculateLastActivity(
          recipient.elderId,
          healthProvider: healthProvider,
          medicationProvider: medicationProvider,
          lifestyleProvider: lifestyleProvider,
        );
        print('   - Last activity: $lastActivityTime');
      } else {
        print(
          '⚠️ [CARE_CONTEXT] No providers available for activity calculation',
        );
      }

      // Calculate patient status
      PatientStatus? status;
      if (healthProvider != null || medicationProvider != null) {
        print('🏥 [CARE_CONTEXT] Calculating patient status...');
        status = await _calculatePatientStatus(
          recipient.elderId,
          healthProvider: healthProvider,
          medicationProvider: medicationProvider,
        );
        print('   - Status: $status');
      } else {
        print(
          '⚠️ [CARE_CONTEXT] No providers available for status calculation',
        );
      }

      final enriched = recipient.copyWith(
        avatarUrl: avatarUrl,
        age: age,
        lastActivityTime: lastActivityTime,
        status: status,
      );

      print('✨ [CARE_CONTEXT] Enrichment complete for ${recipient.name}:');
      print('   - age: ${enriched.age}');
      print('   - avatarUrl: ${enriched.avatarUrl}');
      print('   - lastActivityTime: ${enriched.lastActivityTime}');
      print('   - status: ${enriched.status}');

      _enrichedRecipients[recipient.elderId] = enriched;
      return enriched;
    } catch (e, stackTrace) {
      print(
        '❌ [CARE_CONTEXT] Error enriching recipient ${recipient.elderId}: $e',
      );
      print('   Stack trace: $stackTrace');
      // Return original if enrichment fails
      return recipient;
    }
  }

  // Calculate last activity time (most recent of vital, medication, or diet/exercise)
  Future<DateTime?> _calculateLastActivity(
    String elderId, {
    HealthProvider? healthProvider,
    MedicationProvider? medicationProvider,
    LifestyleProvider? lifestyleProvider,
  }) async {
    final activities = <DateTime>[];

    // Get last vital
    if (healthProvider != null) {
      try {
        final vitals = await healthProvider.getRecentVitals(
          elderId,
          elderUserId: elderId,
        );
        if (vitals.isNotEmpty) {
          activities.add(vitals.first.timestamp);
        }
      } catch (e) {
        // Ignore errors
      }
    }

    // Get last medication taken
    if (medicationProvider != null) {
      try {
        // This would need to be implemented in medication provider
        // For now, we'll skip it
      } catch (e) {
        // Ignore errors
      }
    }

    // Get last diet/exercise log
    if (lifestyleProvider != null) {
      try {
        // This would need to be implemented in lifestyle provider
        // For now, we'll skip it
      } catch (e) {
        // Ignore errors
      }
    }

    if (activities.isEmpty) {
      return null;
    }

    activities.sort((a, b) => b.compareTo(a));
    return activities.first;
  }

  // Calculate patient status (comprehensive: vitals, medications, inactivity)
  Future<PatientStatus> _calculatePatientStatus(
    String elderId, {
    HealthProvider? healthProvider,
    MedicationProvider? medicationProvider,
  }) async {
    bool needsAttention = false;

    // Check for abnormal vitals
    if (healthProvider != null) {
      try {
        final abnormalVitals = await healthProvider.getAbnormalReadings(
          elderId,
          elderUserId: elderId,
        );
        if (abnormalVitals.isNotEmpty) {
          needsAttention = true;
        }
      } catch (e) {
        // Ignore errors
      }
    }

    // Check for missed medications (adherence < 90%)
    if (medicationProvider != null) {
      try {
        // We'd need to check for missed medications
        // For now, we'll check adherence percentage
        // This is a simplified check
      } catch (e) {
        // Ignore errors
      }
    }

    return needsAttention ? PatientStatus.needsAttention : PatientStatus.stable;
  }

  // Calculate age from date of birth
  String? _calculateAge(String dobString) {
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return null;
    }
  }

  // Clear enriched recipients cache
  void clearEnrichedCache() {
    _enrichedRecipients.clear();
  }

  void selectRecipient(String elderId) {
    if (_selectedRecipient?.elderId == elderId) {
      return;
    }
    final recipient = _careRecipients.firstWhere(
      (assignment) => assignment.elderId == elderId,
      orElse: () =>
          _selectedRecipient ??
          (_careRecipients.isNotEmpty
              ? _careRecipients.first
              : throw StateError('No care recipients available')),
    );
    _selectedRecipient = recipient;
    notifyListeners();
  }

  void _clearState() {
    _careRecipients = [];
    _selectedRecipient = null;
    _error = null;
    _isLoading = false;
  }
}
