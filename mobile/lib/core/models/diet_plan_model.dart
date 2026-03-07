import 'diet_log_model.dart';

class DietPlanModel {
  final String id;
  final String planName;
  final String description;
  final bool isActive;
  final String userId;
  final List<DietPlanItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  DietPlanModel({
    required this.id,
    required this.planName,
    required this.description,
    required this.isActive,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  DietPlanModel copyWith({
    String? id,
    String? planName,
    String? description,
    bool? isActive,
    String? userId,
    List<DietPlanItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DietPlanModel(
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

  factory DietPlanModel.fromJson(Map<String, dynamic> json) {
    return DietPlanModel(
      id: json['id']?.toString() ?? '',
      planName: json['planName'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      userId: json['userId']?.toString() ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) =>
                    DietPlanItemModel.fromJson(item as Map<String, dynamic>),
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

class DietPlanItemModel {
  final String id;
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
  final MealType mealType;
  final String description;
  final int calories;
  final String notes;

  DietPlanItemModel({
    required this.id,
    required this.dayOfWeek,
    required this.mealType,
    required this.description,
    required this.calories,
    required this.notes,
  });

  DietPlanItemModel copyWith({
    String? id,
    int? dayOfWeek,
    MealType? mealType,
    String? description,
    int? calories,
    String? notes,
  }) {
    return DietPlanItemModel(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealType: mealType ?? this.mealType,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'mealType': mealType.name,
      'description': description,
      'calories': calories,
      'notes': notes,
    };
  }

  factory DietPlanItemModel.fromJson(Map<String, dynamic> json) {
    return DietPlanItemModel(
      id: json['id']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['mealType'],
        orElse: () => MealType.breakfast,
      ),
      description: json['description'] ?? '',
      calories: json['calories'] ?? 0,
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
