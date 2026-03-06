import '../models/diet_log_model.dart';
import '../models/exercise_log_model.dart';
import '../utils/timezone_util.dart';

/// Maps backend lifestyle response to Flutter models
class LifestyleMapper {
  /// Convert backend API response to DietLogModel
  static DietLogModel dietFromApiResponse(Map<String, dynamic> json) {
    // Convert mealType string to enum
    MealType mealType = MealType.breakfast;
    if (json['mealType'] != null || json['mealTypeCode'] != null) {
      final mealStr = (json['mealType'] ?? json['mealTypeCode']).toString().toLowerCase();
      switch (mealStr) {
        case 'breakfast':
          mealType = MealType.breakfast;
          break;
        case 'lunch':
          mealType = MealType.lunch;
          break;
        case 'dinner':
          mealType = MealType.dinner;
          break;
        case 'snack':
          mealType = MealType.snack;
          break;
        default:
          mealType = MealType.breakfast;
      }
    }

    // Parse timestamp - check multiple possible field names
    DateTime timestamp = DateTime.now();
    if (json['timestamp'] != null) {
      try {
        timestamp = TimezoneUtil.fromPakistanTimeIso8601(json['timestamp'].toString());
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else if (json['logDate'] != null) {
      try {
        // logDate might be a date string (YYYY-MM-DD) or ISO datetime
        final dateStr = json['logDate'].toString();
        if (dateStr.contains('T')) {
          timestamp = DateTime.parse(dateStr);
        } else {
          // Parse date-only string (YYYY-MM-DD)
          timestamp = DateTime.parse('${dateStr}T00:00:00');
        }
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else if (json['loggedAt'] != null) {
      try {
        timestamp = DateTime.parse(json['loggedAt'].toString());
      } catch (e) {
        timestamp = DateTime.now();
      }
    }

    return DietLogModel(
      id: json['id']?.toString() ?? json['dietLogId']?.toString() ?? '',
      mealType: mealType,
      description: json['description']?.toString() ?? '',
      calories: int.tryParse(json['calories']?.toString() ?? '0') ?? 0,
      timestamp: timestamp,
      userId: json['userId']?.toString() ?? json['elderUserId']?.toString() ?? '',
      sourcePlanId: json['sourcePlanId']?.toString(),
    );
  }

  /// Convert DietLogModel to backend API request format
  static Map<String, dynamic> dietToApiRequest(
    DietLogModel diet, {
    String? elderUserId,
  }) {
    // Convert mealType enum to string
    String mealType;
    switch (diet.mealType) {
      case MealType.breakfast:
        mealType = 'breakfast';
        break;
      case MealType.lunch:
        mealType = 'lunch';
        break;
      case MealType.dinner:
        mealType = 'dinner';
        break;
      case MealType.snack:
        mealType = 'snack';
        break;
    }

    // Format date as YYYY-MM-DD (date only, not datetime)
    // Convert to Pakistan timezone first to ensure correct date extraction
    // Extract date components ensuring we use Pakistan timezone perspective
    final logDate = TimezoneUtil.toPakistanTimeIso8601(diet.timestamp).split('T')[0];
    
    return {
      'mealType': mealType,
      'description': diet.description,
      'calories': diet.calories,
      'logDate': logDate,
      if (elderUserId != null && elderUserId.isNotEmpty)
        'elderUserId': elderUserId,
    };
  }

  /// Convert backend API response to ExerciseLogModel
  static ExerciseLogModel exerciseFromApiResponse(Map<String, dynamic> json) {
    // Convert activityType string to enum
    ActivityType activityType = ActivityType.other;
    if (json['activityType'] != null || json['activityTypeCode'] != null) {
      final activityStr = (json['activityType'] ?? json['activityTypeCode']).toString().toLowerCase();
      switch (activityStr) {
        case 'walking':
          activityType = ActivityType.walking;
          break;
        case 'running':
          activityType = ActivityType.running;
          break;
        case 'cycling':
          activityType = ActivityType.cycling;
          break;
        case 'swimming':
          activityType = ActivityType.swimming;
          break;
        case 'yoga':
          activityType = ActivityType.yoga;
          break;
        case 'gym':
          activityType = ActivityType.gym;
          break;
        case 'sports':
          activityType = ActivityType.sports;
          break;
        case 'other':
        default:
          activityType = ActivityType.other;
      }
    }

    // Parse timestamp - check multiple possible field names
    DateTime timestamp = DateTime.now();
    if (json['timestamp'] != null) {
      try {
        timestamp = TimezoneUtil.fromPakistanTimeIso8601(json['timestamp'].toString());
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else if (json['logDate'] != null) {
      try {
        // logDate might be a date string (YYYY-MM-DD) or ISO datetime
        final dateStr = json['logDate'].toString();
        if (dateStr.contains('T')) {
          timestamp = DateTime.parse(dateStr);
        } else {
          // Parse date-only string (YYYY-MM-DD)
          timestamp = DateTime.parse('${dateStr}T00:00:00');
        }
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else if (json['loggedAt'] != null) {
      try {
        timestamp = DateTime.parse(json['loggedAt'].toString());
      } catch (e) {
        timestamp = DateTime.now();
      }
    }

    return ExerciseLogModel(
      id: json['id']?.toString() ?? json['exerciseLogId']?.toString() ?? '',
      activityType: activityType,
      description: json['description']?.toString() ?? '',
      durationMinutes: int.tryParse(json['durationMinutes']?.toString() ?? '0') ?? 0,
      caloriesBurned: int.tryParse(json['caloriesBurned']?.toString() ?? '0') ?? 0,
      timestamp: timestamp,
      userId: json['userId']?.toString() ?? json['elderUserId']?.toString() ?? '',
      sourcePlanId: json['sourcePlanId']?.toString(),
    );
  }

  /// Convert ExerciseLogModel to backend API request format
  static Map<String, dynamic> exerciseToApiRequest(
    ExerciseLogModel exercise, {
    String? elderUserId,
  }) {
    // Convert activityType enum to string
    String activityType;
    switch (exercise.activityType) {
      case ActivityType.walking:
        activityType = 'walking';
        break;
      case ActivityType.running:
        activityType = 'running';
        break;
      case ActivityType.cycling:
        activityType = 'cycling';
        break;
      case ActivityType.swimming:
        activityType = 'swimming';
        break;
      case ActivityType.yoga:
        activityType = 'yoga';
        break;
      case ActivityType.gym:
        activityType = 'gym';
        break;
      case ActivityType.sports:
        activityType = 'sports';
        break;
      case ActivityType.other:
        activityType = 'other';
        break;
    }

    // Format date as YYYY-MM-DD (date only, not datetime)
    // Convert to Pakistan timezone first to ensure correct date extraction
    // Extract date components ensuring we use Pakistan timezone perspective
    final logDate = TimezoneUtil.toPakistanTimeIso8601(exercise.timestamp).split('T')[0];
    
    return {
      'activityType': activityType,
      'description': exercise.description,
      'durationMinutes': exercise.durationMinutes,
      'caloriesBurned': exercise.caloriesBurned,
      'logDate': logDate,
      if (elderUserId != null && elderUserId.isNotEmpty)
        'elderUserId': elderUserId,
    };
  }
}

