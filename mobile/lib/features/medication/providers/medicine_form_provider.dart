import 'package:flutter/material.dart';
import '../../../core/models/medicine_model.dart';

class MedicineFormData {
  String name = '';
  MedicineForm? medicineForm;
  MedicineFrequency? frequency;
  List<int> periodicDays = [];
  List<TimeOfDay> reminderTimes = [];
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  String doseAmount = '';
  String strength = '';
  String notes = '';

  bool get isValid {
    return name.trim().isNotEmpty &&
        medicineForm != null &&
        frequency != null &&
        reminderTimes.isNotEmpty;
  }
}

class MedicineFormProvider extends ChangeNotifier {
  int _currentStep = 0;
  final int _totalSteps = 7;
  final MedicineFormData _formData = MedicineFormData();
  String? _errorMessage;

  int get currentStep => _currentStep;
  int get totalSteps => _totalSteps;
  MedicineFormData get formData => _formData;
  String? get errorMessage => _errorMessage;
  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == _totalSteps - 1;
  double get progress => (_currentStep + 1) / _totalSteps;

  // Step validation
  bool validateCurrentStep() {
    _errorMessage = null;

    switch (_currentStep) {
      case 0: // Medicine name
        if (_formData.name.trim().length < 2) {
          _errorMessage =
              'Please enter a medicine name (at least 2 characters)';
          return false;
        }
        break;
      case 1: // Medicine form
        if (_formData.medicineForm == null) {
          _errorMessage = 'Please select a medicine form';
          return false;
        }
        break;
      case 2: // Frequency
        if (_formData.frequency == null) {
          _errorMessage = 'Please select a frequency';
          return false;
        }
        if (_formData.frequency == MedicineFrequency.periodic &&
            _formData.periodicDays.isEmpty) {
          _errorMessage =
              'Please select at least one day for periodic schedule';
          return false;
        }
        break;
      case 3: // Schedule times
        if (_formData.reminderTimes.isEmpty) {
          _errorMessage = 'Please set at least one reminder time';
          return false;
        }
        break;
      case 4: // Start date
        // Start date is already initialized, no validation needed
        break;
      case 5: // Dose and strength
        // Section is now skippable as per requirements
        break;
      case 6: // Summary - final validation
        if (!_formData.isValid) {
          _errorMessage = 'Please complete all required fields';
          return false;
        }
        break;
    }

    notifyListeners();
    return true;
  }

  // Navigation methods
  bool nextStep() {
    if (validateCurrentStep() && _currentStep < _totalSteps - 1) {
      _currentStep++;
      _autoPopulateTimes();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _errorMessage = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  void goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      _currentStep = step;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Auto-populate times based on frequency
  void _autoPopulateTimes() {
    if (_currentStep == 3 && _formData.frequency != null) {
      switch (_formData.frequency!) {
        case MedicineFrequency.daily:
          _formData.reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
          break;
        case MedicineFrequency.twiceDaily:
          _formData.reminderTimes = [
            const TimeOfDay(hour: 9, minute: 0),
            const TimeOfDay(hour: 21, minute: 0),
          ];
          break;
        case MedicineFrequency.thriceDaily:
          _formData.reminderTimes = [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 14, minute: 0),
            const TimeOfDay(hour: 20, minute: 0),
          ];
          break;
        case MedicineFrequency.periodic:
          if (_formData.reminderTimes.isEmpty) {
            _formData.reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
          }
          break;
        case MedicineFrequency.beforeMeal:
          if (_formData.reminderTimes.isEmpty) {
            _formData.reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
          }
          break;
        case MedicineFrequency.afterMeal:
          if (_formData.reminderTimes.isEmpty) {
            _formData.reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
          }
          break;
        default:
          if (_formData.reminderTimes.isEmpty) {
            _formData.reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
          }
      }
    }
  }

  // Form data setters
  void setMedicineName(String name) {
    _formData.name = name;
    notifyListeners();
  }

  void setMedicineForm(MedicineForm form) {
    _formData.medicineForm = form;
    notifyListeners();
  }

  void setFrequency(MedicineFrequency frequency) {
    _formData.frequency = frequency;
    if (frequency != MedicineFrequency.periodic) {
      _formData.periodicDays.clear();
    }
    notifyListeners();
  }

  void setPeriodicDays(List<int> days) {
    _formData.periodicDays = days;
    notifyListeners();
  }

  void setReminderTimes(List<TimeOfDay> times) {
    _formData.reminderTimes = times;
    notifyListeners();
  }

  void updateReminderTime(int index, TimeOfDay time) {
    if (index >= 0 && index < _formData.reminderTimes.length) {
      _formData.reminderTimes[index] = time;
      notifyListeners();
    }
  }

  void addReminderTime(TimeOfDay time) {
    _formData.reminderTimes.add(time);
    notifyListeners();
  }

  void removeReminderTime(int index) {
    if (index >= 0 &&
        index < _formData.reminderTimes.length &&
        _formData.reminderTimes.length > 1) {
      _formData.reminderTimes.removeAt(index);
      notifyListeners();
    }
  }

  void setStartDate(DateTime date) {
    _formData.startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _formData.endDate = date;
    notifyListeners();
  }

  void setDoseAmount(String amount) {
    _formData.doseAmount = amount;
    notifyListeners();
  }

  void setStrength(String strength) {
    _formData.strength = strength;
    notifyListeners();
  }

  void setNotes(String notes) {
    _formData.notes = notes;
    notifyListeners();
  }

  // Generate MedicineModel from form data
  MedicineModel? generateMedicineModel(String userId) {
    if (!_formData.isValid) return null;

    final dosage = _formData.strength.trim().isNotEmpty
        ? '${_formData.doseAmount.trim()} of ${_formData.strength.trim()}'
        : _formData.doseAmount.trim();

    return MedicineModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _formData.name.trim(),
      dosage: dosage,
      frequency: _formData.frequency!,
      startDate: _formData.startDate,
      endDate: _formData.endDate,
      reminderTimes: _formData.reminderTimes
          .map(
            (t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList(),
      notes: _formData.notes.trim().isEmpty ? null : _formData.notes.trim(),
      userId: userId,
      medicineForm: _formData.medicineForm,
      strength: _formData.strength.trim(),
      doseAmount: _formData.doseAmount.trim(),
      periodicDays: _formData.frequency == MedicineFrequency.periodic
          ? _formData.periodicDays
          : null,
    );
  }

  // Reset form
  void reset() {
    _currentStep = 0;
    _formData.name = '';
    _formData.medicineForm = null;
    _formData.frequency = null;
    _formData.periodicDays.clear();
    _formData.reminderTimes.clear();
    _formData.startDate = DateTime.now();
    _formData.endDate = null;
    _formData.doseAmount = '';
    _formData.strength = '';
    _formData.notes = '';
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
