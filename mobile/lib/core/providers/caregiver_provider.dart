import 'package:flutter/material.dart';
import '../models/caregiver_model.dart';
import '../services/caregiver_service.dart';

class CaregiverProvider with ChangeNotifier {
  final CaregiverService _caregiverService = CaregiverService();
  List<CaregiverModel> _caregivers = [];
  bool _isLoading = false;
  String? _error;

  List<CaregiverModel> get caregivers => _caregivers;
  List<CaregiverModel> get activeCaregivers =>
      _caregivers.where((c) => c.isActive).toList();
  List<CaregiverModel> get inactiveCaregivers =>
      _caregivers.where((c) => !c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load caregivers
  Future<void> loadCaregivers(String patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _caregivers = await _caregiverService.getCaregivers(patientId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send caregiver invitation
  Future<Map<String, dynamic>?> inviteCaregiver({
    required String patientId,
    required String email,
    String? phone,
    String? name,
    String? relationship,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final invitation = await _caregiverService.sendInvitation(
        email: email,
        phone: phone,
        relationship: relationship,
        name: name,
      );

      // Refresh caregiver assignments to include pending invitations
      await loadCaregivers(patientId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return invitation;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Accept invitation
  Future<bool> acceptInvitation(String invitationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _caregiverService.acceptInvitation(invitationId);

      // Reload caregivers to get updated status
      final patientId =
          _caregivers.isNotEmpty ? _caregivers.first.linkedPatientId : '';
      if (patientId.isNotEmpty) {
        await loadCaregivers(patientId);
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

  // Remove caregiver (Hard delete)
  Future<bool> removeCaregiver(String caregiverId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _caregiverService.removeCaregiver(caregiverId);
      _caregivers.removeWhere((c) => c.id == caregiverId);
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

  // Toggle caregiver status (Enable/Disable)
  Future<bool> toggleCaregiverStatus(String assignmentId, bool isActive) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedStatus = await _caregiverService.toggleCaregiverStatus(
        assignmentId,
        isActive,
      );

      // Update local state
      final index = _caregivers.indexWhere((c) => c.id == assignmentId);
      if (index != -1) {
        _caregivers[index] =
            _caregivers[index].copyWith(isActive: updatedStatus);
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
