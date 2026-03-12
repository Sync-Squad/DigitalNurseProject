class VitalMeasurementModel {
  final String id;
  final VitalType type;
  final String value;
  final DateTime timestamp;
  final String? notes;
  final String userId;

  VitalMeasurementModel({
    required this.id,
    required this.type,
    required this.value,
    required this.timestamp,
    this.notes,
    required this.userId,
  });

  VitalMeasurementModel copyWith({
    String? id,
    VitalType? type,
    String? value,
    DateTime? timestamp,
    String? notes,
    String? userId,
  }) {
    return VitalMeasurementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'userId': userId,
    };
  }

  factory VitalMeasurementModel.fromJson(Map<String, dynamic> json) {
    return VitalMeasurementModel(
      id: json['id'],
      type: VitalType.values.firstWhere((e) => e.toString() == json['type']),
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      userId: json['userId'],
    );
  }

  bool isAbnormal() {
    return getHealthStatus() != VitalHealthStatus.normal;
  }

  VitalHealthStatus getHealthStatus() {
    switch (type) {
      case VitalType.bloodPressure:
        final parts = value.split('/');
        if (parts.length == 2) {
          final systolic = int.tryParse(parts[0]) ?? 0;
          final diastolic = int.tryParse(parts[1]) ?? 0;

          // Emergency: Systolic ≥ 180 OR Diastolic ≥ 120
          if (systolic >= 180 || diastolic >= 120) {
            return VitalHealthStatus.emergency;
          }
          // Low BP: Systolic < 90 OR Diastolic < 60
          if (systolic < 90 || diastolic < 60) {
            return VitalHealthStatus.lowBP;
          }
          // Danger: Systolic 140-179 OR Diastolic 90-119
          if (systolic >= 140 || diastolic >= 90) {
            return VitalHealthStatus.danger;
          }
          // Warning: Systolic 121-139 OR Diastolic 81-89
          if (systolic > 120 || diastolic > 80) {
            return VitalHealthStatus.warning;
          }
          // Normal: Systolic 90-120 AND Diastolic 60-80
          return VitalHealthStatus.normal;
        }
        return VitalHealthStatus.normal;

      case VitalType.bloodSugar:
        final sugar = double.tryParse(value) ?? 0;
        // Danger: >125 OR <60 mg/dL
        if (sugar > 125 || sugar < 60) {
          return VitalHealthStatus.danger;
        }
        // Warning: 101-125 OR 60-69 mg/dL
        if (sugar > 100 || sugar < 70) {
          return VitalHealthStatus.warning;
        }
        // Normal: 70-100 mg/dL
        return VitalHealthStatus.normal;

      case VitalType.heartRate:
        final hr = int.tryParse(value) ?? 0;
        // Danger: <50 OR >110 bpm
        if (hr < 50 || hr > 110) {
          return VitalHealthStatus.danger;
        }
        // Warning: 50-59 OR 101-110 bpm
        if (hr < 60 || hr > 100) {
          return VitalHealthStatus.warning;
        }
        // Normal: 60-100 bpm
        return VitalHealthStatus.normal;

      case VitalType.temperature:
        final temp = double.tryParse(value) ?? 0;
        // Danger: <96.0 OR >100.4°F
        if (temp < 96.0 || temp > 100.4) {
          return VitalHealthStatus.danger;
        }
        // Warning: 96.0-96.9 OR 99.6-100.4°F
        if (temp < 97.0 || temp > 99.5) {
          return VitalHealthStatus.warning;
        }
        // Normal: 97.0-99.5°F
        return VitalHealthStatus.normal;

      case VitalType.oxygenSaturation:
        final o2 = int.tryParse(value) ?? 0;
        // Danger: <90%
        if (o2 < 90) {
          return VitalHealthStatus.danger;
        }
        // Warning: 90-94%
        if (o2 < 95) {
          return VitalHealthStatus.warning;
        }
        // Normal: 95-100%
        return VitalHealthStatus.normal;

      case VitalType.weight:
        // Weight has no health status (informational only)
        return VitalHealthStatus.normal;
    }
  }
}

enum VitalHealthStatus {
  normal, // Green
  warning, // Orange
  danger, // Red
  emergency, // Dark Red (Hypertensive Crisis)
  lowBP, // Blue/Purple (Hypotension)
}

enum VitalType {
  bloodPressure,
  bloodSugar,
  heartRate,
  temperature,
  oxygenSaturation,
  weight,
}
