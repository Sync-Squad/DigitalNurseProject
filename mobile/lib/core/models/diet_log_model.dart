class DietLogModel {
  final String id;
  final MealType mealType;
  final String description;
  final int calories;
  final DateTime timestamp;
  final String userId;
  final String? sourcePlanId;

  DietLogModel({
    required this.id,
    required this.mealType,
    required this.description,
    required this.calories,
    required this.timestamp,
    required this.userId,
    this.sourcePlanId,
  });

  DietLogModel copyWith({
    String? id,
    MealType? mealType,
    String? description,
    int? calories,
    DateTime? timestamp,
    String? userId,
    String? sourcePlanId,
  }) {
    return DietLogModel(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sourcePlanId: sourcePlanId ?? this.sourcePlanId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealType': mealType.name,
      'description': description,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      if (sourcePlanId != null) 'sourcePlanId': sourcePlanId,
    };
  }

  factory DietLogModel.fromJson(Map<String, dynamic> json) {
    return DietLogModel(
      id: json['id'],
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['mealType'],
        orElse: () => MealType.breakfast,
      ),
      description: json['description'],
      calories: json['calories'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      sourcePlanId: json['sourcePlanId']?.toString(),
    );
  }
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}
