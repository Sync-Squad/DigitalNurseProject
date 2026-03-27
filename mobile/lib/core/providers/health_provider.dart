import 'package:flutter/material.dart';
import '../models/vital_measurement_model.dart';
import '../services/vitals_service.dart';
import '../utils/timezone_util.dart';

class HealthProvider with ChangeNotifier {
  final VitalsService _vitalsService = VitalsService();
  List<VitalMeasurementModel> _vitals = [];
  bool _isLoading = false;
  String? _error;

  // Cache tracking for "Smart Loading"
  DateTime? _lastFetchTime;
  String? _lastFetchedUserId;
  String? _lastFetchedElderId;

  List<VitalMeasurementModel> get vitals => _vitals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get abnormalVitalsCount => _vitals.where((v) => v.isAbnormal()).length;

  // Load vitals
  Future<void> loadVitals(
    String userId, {
    String? elderUserId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    // 0. Concurrency Lock: Skip if already loading to prevent triple API calls
    if (_isLoading) {
      print('⏭️ [HEALTH] Skipping redundant loadVitals (Already loading...)');
      return;
    }

    // Smart Loading Check: Skip if data is fresh (within 5 seconds) for same user context
    final now = DateTime.now();
    if (_lastFetchTime != null && 
        _lastFetchedUserId == userId && 
        _lastFetchedElderId == elderUserId &&
        now.difference(_lastFetchTime!) < const Duration(seconds: 5)) {
      print('⏭️ [HEALTH] Smart Loading: Skipping redundant fetch (data is fresh)');
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      _vitals = await _vitalsService.getVitals(
        userId,
        elderUserId: elderUserId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      print('🔍 [HEALTH_PROVIDER] Loaded ${_vitals.length} vitals from API');
      for (var v in _vitals) {
        print('   - Vital ${v.id}: ${v.timestamp.toIso8601String()} (PKT: ${TimezoneUtil.toPakistanTime(v.timestamp).toIso8601String()})');
      }
      _error = null;
      _lastFetchTime = DateTime.now();
      _lastFetchedUserId = userId;
      _lastFetchedElderId = elderUserId;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get vitals by type
  Future<List<VitalMeasurementModel>> getVitalsByType(
    String userId,
    VitalType type, {
    String? elderUserId,
  }) async {
    return _vitalsService.getVitalsByType(
      userId,
      type,
      elderUserId: elderUserId,
    );
  }

  // Add vital
  Future<bool> addVital(VitalMeasurementModel vital) async {
    _isLoading = true;
    notifyListeners();

    try {
      final added = await _vitalsService.addVital(vital);
      _vitals.insert(0, added);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update vital
  Future<bool> updateVital(VitalMeasurementModel vital) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _vitalsService.updateVital(vital);
      final index = _vitals.indexWhere((v) => v.id == vital.id);
      if (index != -1) {
        _vitals[index] = updated;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete vital
  Future<bool> deleteVital(String vitalId, {String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _vitalsService.deleteVital(vitalId, elderUserId: elderUserId);
      _vitals.removeWhere((v) => v.id == vitalId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get recent vitals
  Future<List<VitalMeasurementModel>> getRecentVitals(
    String userId, {
    String? elderUserId,
  }) async {
    return await _vitalsService.getRecentVitals(
      userId,
      elderUserId: elderUserId,
    );
  }

  List<VitalMeasurementModel> getVitalsForDate(DateTime date) {
    print('🔍 [HEALTH_PROVIDER] Filtering for date: ${date.year}-${date.month}-${date.day}');
    final filtered = _vitals.where((vital) {
      final pktTime = TimezoneUtil.toPakistanTime(vital.timestamp);
      final isMatch = pktTime.year == date.year &&
          pktTime.month == date.month &&
          pktTime.day == date.day;
      if (isMatch) {
        print('   ✅ Match: Vital ${vital.id} (at ${pktTime.hour}:${pktTime.minute})');
      }
      return isMatch;
    }).toList();
    print('🔍 [HEALTH_PROVIDER] Found ${filtered.length} matches');
    return filtered;
  }

  // Calculate trends
  Future<Map<String, dynamic>> calculateTrends(
    String userId,
    VitalType type, {
    int days = 7,
    String? elderUserId,
  }) async {
    return await _vitalsService.calculateTrends(
      userId,
      type,
      days: days,
      elderUserId: elderUserId,
    );
  }

  // Get abnormal readings
  Future<List<VitalMeasurementModel>> getAbnormalReadings(
    String userId, {
    String? elderUserId,
  }) async {
    return await _vitalsService.getAbnormalReadings(
      userId,
      elderUserId: elderUserId,
    );
  }

  // Initialize mock data (deprecated - no longer needed with API integration)
  @Deprecated('Mock data initialization no longer supported')
  Future<void> initializeMockData(String userId) async {
    // Mock data initialization removed - data now comes from API
    await loadVitals(userId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
