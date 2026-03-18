enum MedicineForm { tablet, capsule, syrup, injection, drops, inhaler, other }

enum MedicinePriority { low, medium, high }

class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final MedicineFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> reminderTimes; // e.g., ["08:00", "14:00", "20:00"]
  final String? notes;
  final String userId;
  final MedicineForm? medicineForm;
  final String? strength; // e.g., "500mg"
  final String? doseAmount; // e.g., "1 tablet", "5ml"
  final List<int>? periodicDays; // 1=Monday, 7=Sunday for periodic frequency
  final MedicinePriority priority;

  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.reminderTimes,
    this.notes,
    required this.userId,
    this.medicineForm,
    this.strength,
    this.doseAmount,
    this.periodicDays,
    this.priority = MedicinePriority.medium,
  });

  MedicineModel copyWith({
    String? id,
    String? name,
    String? dosage,
    MedicineFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? reminderTimes,
    String? notes,
    String? userId,
    MedicineForm? medicineForm,
    String? strength,
    String? doseAmount,
    List<int>? periodicDays,
    MedicinePriority? priority,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      medicineForm: medicineForm ?? this.medicineForm,
      strength: strength ?? this.strength,
      doseAmount: doseAmount ?? this.doseAmount,
      periodicDays: periodicDays ?? this.periodicDays,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'reminderTimes': reminderTimes,
      'notes': notes,
      'userId': userId,
      'medicineForm': medicineForm?.toString(),
      'strength': strength,
      'doseAmount': doseAmount,
      'periodicDays': periodicDays,
      'priority': priority.name,
    };
  }

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: MedicineFrequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
        orElse: () => MedicineFrequency.daily,
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      reminderTimes: List<String>.from(json['reminderTimes']),
      notes: json['notes'],
      userId: json['userId'],
      medicineForm: json['medicineForm'] != null
          ? MedicineForm.values.firstWhere(
              (e) => e.toString() == json['medicineForm'],
              orElse: () => MedicineForm.tablet,
            )
          : null,
      strength: json['strength'],
      doseAmount: json['doseAmount'],
      periodicDays: json['periodicDays'] != null
          ? List<int>.from(json['periodicDays'])
          : null,
      priority: json['priority'] != null
          ? MedicinePriority.values.byName(json['priority'])
          : MedicinePriority.medium,
    );
  }
}

class MedicineIntake {
  final String id;
  final String medicineId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final IntakeStatus status;
  final DateTime? loggedAt;
  final String? note;
  final String? skipReasonCode;
  final String? medicineName;

  MedicineIntake({
    required this.id,
    required this.medicineId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.loggedAt,
    this.note,
    this.skipReasonCode,
    this.medicineName,
  });

  MedicineIntake copyWith({
    String? id,
    String? medicineId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    IntakeStatus? status,
    DateTime? loggedAt,
    String? note,
    String? skipReasonCode,
    String? medicineName,
  }) {
    return MedicineIntake(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      loggedAt: loggedAt ?? this.loggedAt,
      note: note ?? this.note,
      skipReasonCode: skipReasonCode ?? this.skipReasonCode,
      medicineName: medicineName ?? this.medicineName,
    );
  }
}

enum MedicineFrequency {
  daily,
  twiceDaily,
  thriceDaily,
  weekly,
  asNeeded,
  periodic,
  beforeMeal,
  afterMeal,
}

enum IntakeStatus { pending, taken, missed, skipped, snoozed }
