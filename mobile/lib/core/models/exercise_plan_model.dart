import 'exercise_log_model.dart';

class ExercisePlanModel {
  final String id;
  final String planName;
  final String description;
  final bool isActive;
  final String userId;
  final List<ExercisePlanItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExercisePlanModel({
    required this.id,
    required this.planName,
    required this.description,
    required this.isActive,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  ExercisePlanModel copyWith({
    String? id,
    String? planName,
    String? description,
    bool? isActive,
    String? userId,
    List<ExercisePlanItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExercisePlanModel(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'description': description,
      'isActive': isActive,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExercisePlanModel.fromJson(Map<String, dynamic> json) {
    return ExercisePlanModel(
      id: json['id']?.toString() ?? '',
      planName: json['planName'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      userId: json['userId']?.toString() ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => ExercisePlanItemModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class ExercisePlanItemModel {
  final String id;
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
  final ActivityType activityType;
  final String description;
  final int durationMinutes;
  final int caloriesBurned;
  final String intensity;
  final String notes;

  ExercisePlanItemModel({
    required this.id,
    required this.dayOfWeek,
    required this.activityType,
    required this.description,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.intensity,
    required this.notes,
  });

  ExercisePlanItemModel copyWith({
    String? id,
    int? dayOfWeek,
    ActivityType? activityType,
    String? description,
    int? durationMinutes,
    int? caloriesBurned,
    String? intensity,
    String? notes,
  }) {
    return ExercisePlanItemModel(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'activityType': activityType.name,
      'description': description,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'intensity': intensity,
      'notes': notes,
    };
  }

  factory ExercisePlanItemModel.fromJson(Map<String, dynamic> json) {
    return ExercisePlanItemModel(
      id: json['id']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == json['activityType'],
        orElse: () => ActivityType.walking,
      ),
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      intensity: json['intensity'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  String get dayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[dayOfWeek];
  }
}
