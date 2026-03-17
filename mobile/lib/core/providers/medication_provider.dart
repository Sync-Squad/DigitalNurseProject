import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/medication_service.dart';
import '../utils/timezone_util.dart';

class MedicationProvider with ChangeNotifier {
  final MedicationService _medicationService = MedicationService();
  List<MedicineModel> _medicines = [];
  List<Map<String, dynamic>> _upcomingReminders = [];
  bool _isLoading = false;
  String? _error;
  double _adherencePercentage = 100.0;
  int _adherenceStreak = 0;
  List<MedicineIntake> _allIntakes = [];

  List<MedicineModel> get medicines => _medicines;
  List<Map<String, dynamic>> get upcomingReminders => _upcomingReminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get adherencePercentage => _adherencePercentage;
  int get adherenceStreak => _adherenceStreak;
  List<MedicineIntake> get allIntakes => _allIntakes;

  // Load medicines
  Future<void> loadMedicines(String userId, {String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _medicines = await _medicationService.getMedicines(
        userId,
        elderUserId: elderUserId,
      );
      _upcomingReminders = await _medicationService.getUpcomingReminders(
        userId,
        elderUserId: elderUserId,
      );
      _adherencePercentage = await _medicationService.getAdherencePercentage(
        userId,
        elderUserId: elderUserId ?? userId,
      );
      _adherenceStreak = await _medicationService.getAdherenceStreak(
        userId,
        elderUserId: elderUserId ?? userId,
      );

      // Reschedule all medicine reminders after loading
      // Only reschedule if medicines were loaded successfully
      try {
        if (_medicines.isNotEmpty) {
          print('Rescheduling reminders for ${_medicines.length} medicines...');
          await _medicationService.rescheduleAllMedicineReminders(_medicines);
        }
      } catch (e) {
        print('Warning: Failed to reschedule reminders: $e');
        // Don't fail the entire load operation if rescheduling fails
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reschedule all reminders manually
  Future<bool> rescheduleAllReminders(
    String userId, {
    String? elderUserId,
  }) async {
    try {
      if (_medicines.isEmpty) {
        // Reload medicines first
        await loadMedicines(userId, elderUserId: elderUserId);
      }

      final scheduledCount = await _medicationService
          .rescheduleAllMedicineReminders(_medicines);
      print('Rescheduled reminders for $scheduledCount medicines');

      // Refresh upcoming reminders
      await _refreshReminders(userId, elderUserId: elderUserId);

      return scheduledCount > 0;
    } catch (e) {
      print('Error rescheduling all reminders: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add medicine
  Future<bool> addMedicine(MedicineModel medicine) async {
    print('Adding medicine: ${medicine.name}');
    _isLoading = true;
    notifyListeners();

    try {
      final added = await _medicationService.addMedicine(medicine);
      _medicines.add(added);
      print('Medicine added successfully: ${added.name}');
      await _refreshReminders(medicine.userId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding medicine: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update medicine
  Future<bool> updateMedicine(MedicineModel medicine) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _medicationService.updateMedicine(medicine);
      final index = _medicines.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _medicines[index] = updated;
      }
      await _refreshReminders(medicine.userId);
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

  // Delete medicine
  Future<bool> deleteMedicine(
    String medicineId,
    String userId, {
    String? elderUserId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _medicationService.deleteMedicine(
        medicineId,
        elderUserId: elderUserId ?? userId,
      );
      _medicines.removeWhere((m) => m.id == medicineId);
      await _refreshReminders(userId, elderUserId: elderUserId);
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

  // Log intake
  Future<bool> logIntake({
    required String medicineId,
    required DateTime scheduledTime,
    required IntakeStatus status,
    required String userId,
    String? elderUserId,
  }) async {
    try {
      // Only pass elderUserId if explicitly provided (for caregivers)
      // For patients, don't pass it - backend will use the authenticated user's ID
      await _medicationService.logIntake(
        medicineId: medicineId,
        scheduledTime: scheduledTime,
        status: status,
        elderUserId:
            elderUserId, // Don't default to userId - let backend handle it for patients
      );
      // Refresh reminders to sync dashboard
      await _refreshReminders(userId, elderUserId: elderUserId);
      _adherencePercentage = await _medicationService.getAdherencePercentage(
        userId,
        elderUserId: elderUserId ?? userId,
      );
      _adherenceStreak = await _medicationService.getAdherenceStreak(
        userId,
        elderUserId: elderUserId ?? userId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get intake history
  Future<List<MedicineIntake>> getIntakeHistory(
    String medicineId, {
    String? elderUserId,
  }) async {
    return await _medicationService.getIntakeHistory(
      medicineId,
      elderUserId: elderUserId,
    );
  }

  // Load all intake history
  Future<void> loadAllIntakeHistory({String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allIntakes = await _medicationService.getAllIntakeHistory(
        elderUserId: elderUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh reminders
  Future<void> _refreshReminders(String userId, {String? elderUserId}) async {
    _upcomingReminders = await _medicationService.getUpcomingReminders(
      userId,
      elderUserId: elderUserId,
    );
  }

  // Initialize mock data (deprecated - no longer needed with API integration)
  @Deprecated('Mock data initialization no longer supported')
  Future<void> initializeMockData(String userId) async {
    // Mock data initialization removed - data now comes from API
    await loadMedicines(userId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Test immediate notification (for debugging)
  Future<void> testImmediateNotification(String medicineName) async {
    await _medicationService.testImmediateNotification(medicineName);
  }

  // Get medicines for a specific date
  List<MedicineModel> getMedicinesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _medicines.where((medicine) {
      // Check if the medicine is active on this date
      if (medicine.startDate.isAfter(endOfDay)) return false;
      if (medicine.endDate != null && medicine.endDate!.isBefore(startOfDay)) {
        return false;
      }

      // For now, assume all active medicines are taken daily
      // This could be enhanced to check frequency (weekly, etc.)
      return true;
    }).toList();
  }

  // Categorize medicines by time of day based on reminder times
  Map<String, List<MedicineModel>> categorizeMedicinesByTimeOfDay(
    List<MedicineModel> medicines,
  ) {
    final categorized = <String, List<MedicineModel>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
    };

    for (final medicine in medicines) {
      final timeCategories = <String>{};

      for (final timeStr in medicine.reminderTimes) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;

        final hour = int.tryParse(parts[0]);
        if (hour == null) continue;

        if (hour < 12) {
          timeCategories.add('morning');
        } else if (hour < 17) {
          timeCategories.add('afternoon');
        } else {
          timeCategories.add('evening');
        }
      }

      // Add medicine to all relevant time categories
      for (final category in timeCategories) {
        if (!categorized[category]!.contains(medicine)) {
          categorized[category]!.add(medicine);
        }
      }
    }

    return categorized;
  }

  // Get medicine status for a specific time on a specific date
  Future<IntakeStatus> getMedicineStatus(
    MedicineModel medicine,
    String reminderTime,
    DateTime date,
  ) async {
    final parts = reminderTime.split(':');
    if (parts.length != 2) return IntakeStatus.pending;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return IntakeStatus.pending;

    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    // Get intake history for this specific medicine and time
    final intakeHistory = await getIntakeHistory(
      medicine.id,
      elderUserId: medicine.userId,
    );

    // Check if there's an intake record for this specific scheduled time
    final intake = intakeHistory.firstWhere(
      (i) =>
          i.scheduledTime.year == scheduledDateTime.year &&
          i.scheduledTime.month == scheduledDateTime.month &&
          i.scheduledTime.day == scheduledDateTime.day &&
          i.scheduledTime.hour == scheduledDateTime.hour &&
          i.scheduledTime.minute == scheduledDateTime.minute,
      orElse: () => MedicineIntake(
        id: '',
        medicineId: medicine.id,
        scheduledTime: scheduledDateTime,
        status: IntakeStatus.pending,
      ),
    );

    // If there's a record, return its status
    if (intake.id.isNotEmpty) {
      return intake.status;
    }

    // If no record and time has passed, it's missed
    if (scheduledDateTime.isBefore(TimezoneUtil.nowInPakistan())) {
      return IntakeStatus.missed;
    }

    // If time hasn't passed yet, it's upcoming
    return IntakeStatus.pending;
  }

  // Get time of day string for display
  String getTimeOfDayString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return timeStr;

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }
}
