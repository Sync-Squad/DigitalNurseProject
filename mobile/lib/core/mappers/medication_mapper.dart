import '../models/medicine_model.dart';
import '../utils/timezone_util.dart';

/// Maps backend medication response to Flutter MedicineModel
class MedicationMapper {
  /// Convert backend API response to MedicineModel
  static MedicineModel fromApiResponse(Map<String, dynamic> json) {
    // Extract reminderTimes from array of objects with 'time' property
    List<String> reminderTimes = [];
    if (json['reminderTimes'] != null) {
      if (json['reminderTimes'] is List) {
        for (var item in json['reminderTimes']) {
          if (item is Map && item['time'] != null) {
            reminderTimes.add(item['time'].toString());
          } else if (item is String) {
            reminderTimes.add(item);
          }
        }
      }
    }

    // Convert frequency string to enum
    MedicineFrequency frequency = MedicineFrequency.daily;
    if (json['frequency'] != null) {
      final freqStr = json['frequency'].toString().toLowerCase();
      switch (freqStr) {
        case 'daily':
          frequency = MedicineFrequency.daily;
          break;
        case 'twicedaily':
        case 'twice_daily':
          frequency = MedicineFrequency.twiceDaily;
          break;
        case 'thricedaily':
        case 'thrice_daily':
          frequency = MedicineFrequency.thriceDaily;
          break;
        case 'weekly':
          frequency = MedicineFrequency.weekly;
          break;
        case 'asneeded':
        case 'as_needed':
          frequency = MedicineFrequency.asNeeded;
          break;
        case 'periodic':
          frequency = MedicineFrequency.periodic;
          break;
        case 'beforemeal':
        case 'before_meal':
          frequency = MedicineFrequency.beforeMeal;
          break;
        case 'aftermeal':
        case 'after_meal':
          frequency = MedicineFrequency.afterMeal;
          break;
      }
    }

    // Convert medicineForm string to enum
    MedicineForm? medicineForm;
    if (json['medicineForm'] != null) {
      final formStr = json['medicineForm'].toString().toLowerCase();
      switch (formStr) {
        case 'tablet':
          medicineForm = MedicineForm.tablet;
          break;
        case 'capsule':
          medicineForm = MedicineForm.capsule;
          break;
        case 'syrup':
          medicineForm = MedicineForm.syrup;
          break;
        case 'injection':
          medicineForm = MedicineForm.injection;
          break;
        case 'drops':
          medicineForm = MedicineForm.drops;
          break;
        case 'inhaler':
          medicineForm = MedicineForm.inhaler;
          break;
        case 'other':
          medicineForm = MedicineForm.other;
          break;
      }
    }

    // Parse dates
    DateTime startDate = DateTime.now();
    if (json['startDate'] != null) {
      try {
        startDate = DateTime.parse(json['startDate'].toString());
      } catch (e) {
        startDate = DateTime.now();
      }
    }

    DateTime? endDate;
    if (json['endDate'] != null) {
      try {
        endDate = DateTime.parse(json['endDate'].toString());
      } catch (e) {
        endDate = null;
      }
    }

    // Parse periodicDays
    List<int>? periodicDays;
    if (json['periodicDays'] != null && json['periodicDays'] is List) {
      periodicDays = (json['periodicDays'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
      if (periodicDays.isEmpty) periodicDays = null;
    }

    // Parse priority
    MedicinePriority priority = MedicinePriority.medium;
    if (json['priority'] != null) {
      final priorityStr = json['priority'].toString().toLowerCase();
      switch (priorityStr) {
        case 'low':
          priority = MedicinePriority.low;
          break;
        case 'high':
          priority = MedicinePriority.high;
          break;
        default:
          priority = MedicinePriority.medium;
      }
    }

    return MedicineModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      reminderTimes: reminderTimes,
      notes: json['notes']?.toString(),
      userId: json['userId']?.toString() ?? '',
      medicineForm: medicineForm,
      strength: json['strength']?.toString(),
      doseAmount: json['doseAmount']?.toString(),
      periodicDays: periodicDays,
      priority: priority,
    );
  }

  /// Convert MedicineModel to backend API request format
  static Map<String, dynamic> toApiRequest(
    MedicineModel medicine, {
    String? elderUserId,
  }) {
    // Convert reminderTimes to array of objects
    final reminderTimes = medicine.reminderTimes
        .map((time) => {'time': time})
        .toList();

    // Convert frequency enum to string
    String frequency;
    switch (medicine.frequency) {
      case MedicineFrequency.daily:
        frequency = 'daily';
        break;
      case MedicineFrequency.twiceDaily:
        frequency = 'twiceDaily';
        break;
      case MedicineFrequency.thriceDaily:
        frequency = 'thriceDaily';
        break;
      case MedicineFrequency.weekly:
        frequency = 'weekly';
        break;
      case MedicineFrequency.asNeeded:
        frequency = 'asNeeded';
        break;
      case MedicineFrequency.periodic:
        frequency = 'periodic';
        break;
      case MedicineFrequency.beforeMeal:
        frequency = 'beforeMeal';
        break;
      case MedicineFrequency.afterMeal:
        frequency = 'afterMeal';
        break;
    }

    // Convert medicineForm enum to string
    String? medicineForm;
    if (medicine.medicineForm != null) {
      switch (medicine.medicineForm!) {
        case MedicineForm.tablet:
          medicineForm = 'tablet';
          break;
        case MedicineForm.capsule:
          medicineForm = 'capsule';
          break;
        case MedicineForm.syrup:
          medicineForm = 'syrup';
          break;
        case MedicineForm.injection:
          medicineForm = 'injection';
          break;
        case MedicineForm.drops:
          medicineForm = 'drops';
          break;
        case MedicineForm.inhaler:
          medicineForm = 'inhaler';
          break;
        case MedicineForm.other:
          medicineForm = 'other';
          break;
      }
    }

    return {
      'name': medicine.name,
      'dosage': medicine.dosage,
      'frequency': frequency,
      'startDate': medicine.startDate.toIso8601String().split('T')[0],
      if (medicine.endDate != null)
        'endDate': medicine.endDate!.toIso8601String().split('T')[0],
      'reminderTimes': reminderTimes,
      if (medicine.notes != null) 'notes': medicine.notes,
      if (medicineForm != null) 'medicineForm': medicineForm,
      if (medicine.strength != null) 'strength': medicine.strength,
      if (medicine.doseAmount != null) 'doseAmount': medicine.doseAmount,
      if (medicine.periodicDays != null) 'periodicDays': medicine.periodicDays,
      if (elderUserId != null) 'elderUserId': elderUserId,
      'priority': medicine.priority.name,
    };
  }

  /// Convert intake API response to MedicineIntake
  static MedicineIntake intakeFromApiResponse(Map<String, dynamic> json) {
    // Convert status string to enum
    IntakeStatus status = IntakeStatus.pending;
    if (json['status'] != null) {
      final statusStr = json['status'].toString().toLowerCase();
      switch (statusStr) {
        case 'taken':
          status = IntakeStatus.taken;
          break;
        case 'missed':
          status = IntakeStatus.missed;
          break;
        case 'skipped':
          status = IntakeStatus.skipped;
          break;
        default:
          status = IntakeStatus.pending;
      }
    }

    DateTime scheduledTime = DateTime.now();
    if (json['scheduledTime'] != null) {
      try {
        scheduledTime = DateTime.parse(json['scheduledTime'].toString());
      } catch (e) {
        scheduledTime = DateTime.now();
      }
    }

    DateTime? takenTime;
    if (json['takenTime'] != null) {
      try {
        takenTime = DateTime.parse(json['takenTime'].toString());
      } catch (e) {
        takenTime = null;
      }
    }

    return MedicineIntake(
      id: json['id']?.toString() ?? '',
      medicineId: json['medicationId']?.toString() ?? '',
      scheduledTime: scheduledTime,
      takenTime: takenTime,
      status: status,
    );
  }

  /// Convert MedicineIntake to API request format
  static Map<String, dynamic> intakeToApiRequest(
    MedicineIntake intake, {
    String? elderUserId,
  }) {
    String status;
    switch (intake.status) {
      case IntakeStatus.taken:
        status = 'taken';
        break;
      case IntakeStatus.missed:
        status = 'missed';
        break;
      case IntakeStatus.skipped:
        status = 'skipped';
        break;
      default:
        status = 'pending';
    }

    // Convert to Pakistan timezone to ensure consistent timezone handling
    return {
      'scheduledTime': TimezoneUtil.toPakistanTimeIso8601(intake.scheduledTime),
      'status': status,
      if (intake.takenTime != null)
        'takenTime': TimezoneUtil.toPakistanTimeIso8601(intake.takenTime!),
      if (elderUserId != null) 'elderUserId': elderUserId,
    };
  }
}
