import '../models/diet_log_model.dart';
import '../models/exercise_log_model.dart';
import '../models/diet_plan_model.dart';
import '../models/exercise_plan_model.dart';
import '../mappers/lifestyle_mapper.dart';
import '../utils/timezone_util.dart';
import 'api_service.dart';

class DietExerciseService {
  final ApiService _apiService = ApiService();

  void _log(String message) {
    print('🔍 [LIFESTYLE] $message');
  }

  // Diet Log Methods
  Future<List<DietLogModel>> getDietLogs(
    String userId, {
    DateTime? date,
    DateTime? startDate,
    String? elderUserId,
  }) async {
    _log(
      '📋 Fetching diet logs for user: $userId${date != null ? ' on ${date.toString().split(' ')[0]}' : ''}',
    );
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = TimezoneUtil.toPakistanTimeIso8601(
          date,
        ).split('T')[0];
      }
      if (startDate != null) {
        queryParams['startDate'] = TimezoneUtil.toPakistanTimeIso8601(
          startDate,
        ).split('T')[0];
      }
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/lifestyle/diet',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final dietLogs =
            data
                .map(
                  (json) => LifestyleMapper.dietFromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _log('✅ Fetched ${dietLogs.length} diet logs');
        return dietLogs;
      } else {
        _log('❌ Failed to fetch diet logs: ${response.statusMessage}');
        throw Exception('Failed to fetch diet logs: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error fetching diet logs: $e');
      throw Exception(e.toString());
    }
  }

  Future<DietLogModel> addDietLog(DietLogModel dietLog) async {
    _log('➕ Adding diet log: ${dietLog.mealType}');
    try {
      final requestData = LifestyleMapper.dietToApiRequest(
        dietLog,
        elderUserId: dietLog.userId,
      );
      _log('📤 Request data: $requestData');
      
      final response = await _apiService.post(
        '/lifestyle/diet',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final addedLog = LifestyleMapper.dietFromApiResponse(response.data);
        _log('✅ Diet log added successfully');
        return addedLog;
      } else {
        _log('❌ Failed to add diet log: ${response.statusMessage}');
        throw Exception('Failed to add diet log: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error adding diet log: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> deleteDietLog(String logId, {String? elderUserId}) async {
    _log('🗑️ Deleting diet log: $logId');
    try {
      final response = await _apiService.delete(
        '/lifestyle/diet/$logId',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        _log('✅ Diet log deleted successfully');
      } else {
        _log('❌ Failed to delete diet log: ${response.statusMessage}');
        throw Exception('Failed to delete diet log: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error deleting diet log: $e');
      throw Exception(e.toString());
    }
  }

  // Exercise Log Methods
  Future<List<ExerciseLogModel>> getExerciseLogs(
    String userId, {
    DateTime? date,
    DateTime? startDate,
    String? elderUserId,
  }) async {
    _log(
      '📋 Fetching exercise logs for user: $userId${date != null ? ' on ${date.toString().split(' ')[0]}' : ''}',
    );
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = TimezoneUtil.toPakistanTimeIso8601(
          date,
        ).split('T')[0];
      }
      if (startDate != null) {
        queryParams['startDate'] = TimezoneUtil.toPakistanTimeIso8601(
          startDate,
        ).split('T')[0];
      }
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/lifestyle/exercise',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final exerciseLogs =
            data
                .map(
                  (json) => LifestyleMapper.exerciseFromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _log('✅ Fetched ${exerciseLogs.length} exercise logs');
        return exerciseLogs;
      } else {
        _log('❌ Failed to fetch exercise logs: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch exercise logs: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching exercise logs: $e');
      throw Exception(e.toString());
    }
  }

  Future<ExerciseLogModel> addExerciseLog(ExerciseLogModel exerciseLog) async {
    _log('➕ Adding exercise log: ${exerciseLog.activityType}');
    try {
      final requestData = LifestyleMapper.exerciseToApiRequest(
        exerciseLog,
        elderUserId: exerciseLog.userId,
      );
      final response = await _apiService.post(
        '/lifestyle/exercise',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final addedLog = LifestyleMapper.exerciseFromApiResponse(response.data);
        _log('✅ Exercise log added successfully');
        return addedLog;
      } else {
        _log('❌ Failed to add exercise log: ${response.statusMessage}');
        throw Exception(
          'Failed to add exercise log: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error adding exercise log: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> deleteExerciseLog(String logId, {String? elderUserId}) async {
    _log('🗑️ Deleting exercise log: $logId');
    try {
      final response = await _apiService.delete(
        '/lifestyle/exercise/$logId',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        _log('✅ Exercise log deleted successfully');
      } else {
        _log('❌ Failed to delete exercise log: ${response.statusMessage}');
        throw Exception(
          'Failed to delete exercise log: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error deleting exercise log: $e');
      throw Exception(e.toString());
    }
  }

  // Daily Summary
  Future<Map<String, dynamic>> getDailySummary(
    String userId,
    DateTime date, {
    String? elderUserId,
  }) async {
    _log(
      '📊 Fetching daily summary for user: $userId on ${date.toString().split(' ')[0]}',
    );
    try {
      final queryParameters = {
        'date': TimezoneUtil.toPakistanTimeIso8601(date).split('T')[0],
      };
      if (elderUserId != null) {
        queryParameters['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/lifestyle/summary',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _log('✅ Daily summary fetched successfully');
        return {
          'date': date,
          'caloriesIn': (data['caloriesIn'] ?? 0) as int,
          'caloriesOut': (data['caloriesOut'] ?? 0) as int,
          'netCalories': (data['netCalories'] ?? 0) as int,
          'exerciseMinutes': (data['exerciseMinutes'] ?? 0) as int,
          'mealCount': (data['mealCount'] ?? 0) as int,
          'workoutCount': (data['workoutCount'] ?? 0) as int,
        };
      } else {
        _log('❌ Failed to fetch daily summary: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch daily summary: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching daily summary: $e');
      throw Exception(e.toString());
    }
  }

  // Weekly Summary
  Future<Map<String, dynamic>> getWeeklySummary(
    String userId, {
    String? elderUserId,
  }) async {
    _log('📊 Fetching weekly summary for user: $userId');
    try {
      final response = await _apiService.get(
        '/lifestyle/summary/weekly',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _log('✅ Weekly summary fetched successfully');
        return {
          'weekStart': data['weekStart'] != null
              ? DateTime.parse(data['weekStart'].toString())
              : DateTime.now().subtract(const Duration(days: 7)),
          'weekEnd': data['weekEnd'] != null
              ? DateTime.parse(data['weekEnd'].toString())
              : DateTime.now(),
          'totalCaloriesIn': (data['totalCaloriesIn'] ?? 0) as int,
          'totalCaloriesOut': (data['totalCaloriesOut'] ?? 0) as int,
          'avgCaloriesPerDay': (data['avgCaloriesPerDay'] ?? 0.0).toDouble(),
          'totalExerciseMinutes': (data['totalExerciseMinutes'] ?? 0) as int,
          'avgExercisePerDay': (data['avgExercisePerDay'] ?? 0.0).toDouble(),
        };
      } else {
        _log('❌ Failed to fetch weekly summary: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch weekly summary: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching weekly summary: $e');
      throw Exception(e.toString());
    }
  }

  // ============================================
  // Diet Plan Methods
  // ============================================

  Future<List<DietPlanModel>> getDietPlans({String? elderUserId}) async {
    _log('📋 Fetching diet plans');
    try {
      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/lifestyle/diet-plans',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final plans = data
            .map(
              (json) => DietPlanModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json),
              ),
            )
            .toList();
        _log('✅ Fetched ${plans.length} diet plans');
        return plans;
      } else {
        _log('❌ Failed to fetch diet plans: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch diet plans: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching diet plans: $e');
      throw Exception(e.toString());
    }
  }

  Future<DietPlanModel> getDietPlanById(
    String planId, {
    String? elderUserId,
  }) async {
    _log('📋 Fetching diet plan: $planId');
    try {
      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/lifestyle/diet-plans/$planId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final plan = DietPlanModel.fromJson(response.data);
        _log('✅ Fetched diet plan successfully');
        return plan;
      } else {
        _log('❌ Failed to fetch diet plan: ${response.statusMessage}');
        throw Exception('Failed to fetch diet plan: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error fetching diet plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<DietPlanModel> createDietPlan(
    DietPlanModel plan, {
    String? elderUserId,
  }) async {
    _log('➕ Creating diet plan: ${plan.planName}');
    try {
      final requestData = <String, dynamic>{
        'planName': plan.planName,
        'description': plan.description,
        'items': plan.items
            .map(
              (item) => <String, dynamic>{
                'dayOfWeek': item.dayOfWeek,
                'mealType': item.mealType.name,
                'description': item.description,
                'calories': item.calories,
                'notes': item.notes,
              },
            )
            .toList(),
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final response = await _apiService.post(
        '/lifestyle/diet-plans',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdPlan = DietPlanModel.fromJson(response.data);
        _log('✅ Diet plan created successfully');
        return createdPlan;
      } else {
        _log('❌ Failed to create diet plan: ${response.statusMessage}');
        throw Exception(
          'Failed to create diet plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error creating diet plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<DietPlanModel> updateDietPlan(
    String planId,
    DietPlanModel plan, {
    String? elderUserId,
  }) async {
    _log('✏️ Updating diet plan: $planId');
    try {
      final requestData = <String, dynamic>{
        'planName': plan.planName,
        'description': plan.description,
        'items': plan.items
            .map(
              (item) => <String, dynamic>{
                'dayOfWeek': item.dayOfWeek,
                'mealType': item.mealType.name,
                'description': item.description,
                'calories': item.calories,
                'notes': item.notes,
              },
            )
            .toList(),
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.put(
        '/lifestyle/diet-plans/$planId',
        data: requestData,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final updatedPlan = DietPlanModel.fromJson(response.data);
        _log('✅ Diet plan updated successfully');
        return updatedPlan;
      } else {
        _log('❌ Failed to update diet plan: ${response.statusMessage}');
        throw Exception(
          'Failed to update diet plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error updating diet plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> deleteDietPlan(String planId, {String? elderUserId}) async {
    _log('🗑️ Deleting diet plan: $planId');
    try {
      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.delete(
        '/lifestyle/diet-plans/$planId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        _log('✅ Diet plan deleted successfully');
      } else {
        _log('❌ Failed to delete diet plan: ${response.statusMessage}');
        throw Exception(
          'Failed to delete diet plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error deleting diet plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> applyDietPlan(
    String planId,
    DateTime startDate,
    bool overwriteExisting, {
    String? elderUserId,
  }) async {
    _log('📅 Applying diet plan: $planId');
    try {
      final requestData = {
        'startDate': TimezoneUtil.toPakistanTimeIso8601(
          startDate,
        ).split('T')[0],
        'overwriteExisting': overwriteExisting,
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final response = await _apiService.post(
        '/lifestyle/diet-plans/$planId/apply',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Diet plan applied successfully');
        return response.data;
      } else {
        _log('❌ Failed to apply diet plan: ${response.statusMessage}');
        throw Exception('Failed to apply diet plan: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error applying diet plan: $e');
      throw Exception(e.toString());
    }
  }

  // ============================================
  // Exercise Plan Methods
  // ============================================

  Future<List<ExercisePlanModel>> getExercisePlans({
    String? elderUserId,
  }) async {
    _log('📋 Fetching exercise plans');
    try {
      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/lifestyle/exercise-plans',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final plans = data
            .map(
              (json) => ExercisePlanModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json),
              ),
            )
            .toList();
        _log('✅ Fetched ${plans.length} exercise plans');
        return plans;
      } else {
        _log('❌ Failed to fetch exercise plans: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch exercise plans: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching exercise plans: $e');
      throw Exception(e.toString());
    }
  }

  Future<ExercisePlanModel> getExercisePlanById(
    String planId, {
    String? elderUserId,
  }) async {
    _log('📋 Fetching exercise plan: $planId');
    try {
      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/lifestyle/exercise-plans/$planId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final plan = ExercisePlanModel.fromJson(response.data);
        _log('✅ Fetched exercise plan successfully');
        return plan;
      } else {
        _log('❌ Failed to fetch exercise plan: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch exercise plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching exercise plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<ExercisePlanModel> createExercisePlan(
    ExercisePlanModel plan, {
    String? elderUserId,
  }) async {
    _log('➕ Creating exercise plan: ${plan.planName}');
    try {
      final requestData = <String, dynamic>{
        'planName': plan.planName,
        'description': plan.description,
        'items': plan.items
            .map(
              (item) => <String, dynamic>{
                'dayOfWeek': item.dayOfWeek,
                'activityType': item.activityType.name,
                'description': item.description,
                'durationMinutes': item.durationMinutes,
                'caloriesBurned': item.caloriesBurned,
                'intensity': item.intensity,
                'notes': item.notes,
              },
            )
            .toList(),
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final response = await _apiService.post(
        '/lifestyle/exercise-plans',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdPlan = ExercisePlanModel.fromJson(response.data);
        _log('✅ Exercise plan created successfully');
        return createdPlan;
      } else {
        _log('❌ Failed to create exercise plan: ${response.statusMessage}');
        throw Exception(
          'Failed to create exercise plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error creating exercise plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<ExercisePlanModel> updateExercisePlan(
    String planId,
    ExercisePlanModel plan, {
    String? elderUserId,
  }) async {
    _log('✏️ Updating exercise plan: $planId');
    try {
      final requestData = <String, dynamic>{
        'planName': plan.planName,
        'description': plan.description,
        'items': plan.items
            .map(
              (item) => <String, dynamic>{
                'dayOfWeek': item.dayOfWeek,
                'activityType': item.activityType.name,
                'description': item.description,
                'durationMinutes': item.durationMinutes,
                'caloriesBurned': item.caloriesBurned,
                'intensity': item.intensity,
                'notes': item.notes,
              },
            )
            .toList(),
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.put(
        '/lifestyle/exercise-plans/$planId',
        data: requestData,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final updatedPlan = ExercisePlanModel.fromJson(response.data);
        _log('✅ Exercise plan updated successfully');
        return updatedPlan;
      } else {
        _log('❌ Failed to update exercise plan: ${response.statusMessage}');
        throw Exception(
          'Failed to update exercise plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error updating exercise plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> deleteExercisePlan(String planId, {String? elderUserId}) async {
    _log('🗑️ Deleting exercise plan: $planId');
    try {
      final queryParams = <String, dynamic>{};
      if (elderUserId != null) {
        queryParams['elderUserId'] = elderUserId;
      }

      final response = await _apiService.delete(
        '/lifestyle/exercise-plans/$planId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        _log('✅ Exercise plan deleted successfully');
      } else {
        _log('❌ Failed to delete exercise plan: ${response.statusMessage}');
        throw Exception(
          'Failed to delete exercise plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error deleting exercise plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> applyExercisePlan(
    String planId,
    DateTime startDate,
    bool overwriteExisting, {
    String? elderUserId,
  }) async {
    _log('📅 Applying exercise plan: $planId');
    try {
      final requestData = {
        'startDate': TimezoneUtil.toPakistanTimeIso8601(
          startDate,
        ).split('T')[0],
        'overwriteExisting': overwriteExisting,
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final response = await _apiService.post(
        '/lifestyle/exercise-plans/$planId/apply',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Exercise plan applied successfully');
        return response.data;
      } else {
        _log('❌ Failed to apply exercise plan: ${response.statusMessage}');
        throw Exception(
          'Failed to apply exercise plan: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error applying exercise plan: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getDietPlanCompliance(
    String planId,
    DateTime startDate,
    DateTime endDate, {
    String? elderUserId,
  }) async {
    _log('📊 Getting diet plan compliance: $planId');
    try {
      final queryParams = <String, dynamic>{
        'startDate': TimezoneUtil.toPakistanTimeIso8601(
          startDate,
        ).split('T')[0],
        'endDate': TimezoneUtil.toPakistanTimeIso8601(endDate).split('T')[0],
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final response = await _apiService.get(
        '/lifestyle/diet-plans/$planId/compliance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        _log('✅ Diet plan compliance retrieved successfully');
        return response.data;
      } else {
        _log('❌ Failed to get diet plan compliance: ${response.statusMessage}');
        throw Exception(
          'Failed to get diet plan compliance: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error getting diet plan compliance: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getExercisePlanCompliance(
    String planId,
    DateTime startDate,
    DateTime endDate, {
    String? elderUserId,
  }) async {
    _log('📊 Getting exercise plan compliance: $planId');
    try {
      final queryParams = <String, dynamic>{
        'startDate': TimezoneUtil.toPakistanTimeIso8601(
          startDate,
        ).split('T')[0],
        'endDate': TimezoneUtil.toPakistanTimeIso8601(endDate).split('T')[0],
        if (elderUserId != null) 'elderUserId': elderUserId,
      };

      final response = await _apiService.get(
        '/lifestyle/exercise-plans/$planId/compliance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        _log('✅ Exercise plan compliance retrieved successfully');
        return response.data;
      } else {
        _log(
          '❌ Failed to get exercise plan compliance: ${response.statusMessage}',
        );
        throw Exception(
          'Failed to get exercise plan compliance: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error getting exercise plan compliance: $e');
      throw Exception(e.toString());
    }
  }
}
