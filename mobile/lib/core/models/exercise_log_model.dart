class ExerciseLogModel {
  final String id;
  final ActivityType activityType;
  final String description;
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime timestamp;
  final String userId;
  final String? sourcePlanId;

  ExerciseLogModel({
    required this.id,
    required this.activityType,
    required this.description,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.timestamp,
    required this.userId,
    this.sourcePlanId,
  });

  ExerciseLogModel copyWith({
    String? id,
    ActivityType? activityType,
    String? description,
    int? durationMinutes,
    int? caloriesBurned,
    DateTime? timestamp,
    String? userId,
    String? sourcePlanId,
  }) {
    return ExerciseLogModel(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sourcePlanId: sourcePlanId ?? this.sourcePlanId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType.name,
      'description': description,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      if (sourcePlanId != null) 'sourcePlanId': sourcePlanId,
    };
  }

  factory ExerciseLogModel.fromJson(Map<String, dynamic> json) {
    return ExerciseLogModel(
      id: json['id'],
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == json['activityType'],
        orElse: () => ActivityType.walking,
      ),
      description: json['description'],
      durationMinutes: json['durationMinutes'],
      caloriesBurned: json['caloriesBurned'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      sourcePlanId: json['sourcePlanId']?.toString(),
    );
  }
}

enum ActivityType {
  walking,
  running,
  cycling,
  swimming,
  yoga,
  gym,
  sports,
  other,
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.swimming:
        return 'Swimming';
      case ActivityType.yoga:
        return 'Yoga';
      case ActivityType.gym:
        return 'Gym';
      case ActivityType.sports:
        return 'Sports';
      case ActivityType.other:
        return 'Other';
    }
  }
}
