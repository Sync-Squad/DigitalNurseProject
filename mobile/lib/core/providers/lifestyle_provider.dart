import 'package:flutter/material.dart';
import '../models/diet_log_model.dart';
import '../models/exercise_log_model.dart';
import '../models/diet_plan_model.dart';
import '../models/exercise_plan_model.dart';
import '../services/diet_exercise_service.dart';
import '../utils/timezone_util.dart';

class LifestyleProvider with ChangeNotifier {
  final DietExerciseService _service = DietExerciseService();
  List<DietLogModel> _dietLogs = [];
  List<ExerciseLogModel> _exerciseLogs = [];
  List<DietLogModel> _trendDietLogs = [];
  List<ExerciseLogModel> _trendExerciseLogs = [];
  List<DietPlanModel> _dietPlans = [];
  List<ExercisePlanModel> _exercisePlans = [];
  Map<String, dynamic>? _dailySummary;
  bool _isLoading = false;
  String? _error;

  List<DietLogModel> get dietLogs => _dietLogs;
  List<ExerciseLogModel> get exerciseLogs => _exerciseLogs;
  List<DietLogModel> get trendDietLogs => _trendDietLogs;
  List<ExerciseLogModel> get trendExerciseLogs => _trendExerciseLogs;
  List<DietPlanModel> get dietPlans => _dietPlans;
  List<ExercisePlanModel> get exercisePlans => _exercisePlans;
  Map<String, dynamic>? get dailySummary => _dailySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load diet logs
  Future<void> loadDietLogs(
    String userId, {
    DateTime? date,
    String? elderUserId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _dietLogs = await _service.getDietLogs(
        userId,
        date: date,
        elderUserId: elderUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load exercise logs
  Future<void> loadExerciseLogs(
    String userId, {
    DateTime? date,
    String? elderUserId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _exerciseLogs = await _service.getExerciseLogs(
        userId,
        date: date,
        elderUserId: elderUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load both diet and exercise logs
  Future<void> loadAll(
    String userId, {
    DateTime? date,
    String? elderUserId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _dietLogs = await _service.getDietLogs(
        userId,
        date: date,
        elderUserId: elderUserId,
      );
      _exerciseLogs = await _service.getExerciseLogs(
        userId,
        date: date,
        elderUserId: elderUserId,
      );
      _dailySummary = await _service.getDailySummary(
        userId,
        date ?? DateTime.now(),
        elderUserId: elderUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add diet log
  Future<bool> addDietLog(DietLogModel dietLog) async {
    try {
      final added = await _service.addDietLog(dietLog);
      _dietLogs.insert(0, added);
      _dailySummary = await _service.getDailySummary(
        dietLog.userId,
        dietLog.timestamp,
        elderUserId: dietLog.userId,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete diet log
  Future<bool> deleteDietLog(
    String logId,
    String userId, {
    String? elderUserId,
  }) async {
    try {
      await _service.deleteDietLog(logId, elderUserId: elderUserId);
      _dietLogs.removeWhere((d) => d.id == logId);
      _dailySummary = await _service.getDailySummary(
        userId,
        DateTime.now(),
        elderUserId: elderUserId,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add exercise log
  Future<bool> addExerciseLog(ExerciseLogModel exerciseLog) async {
    try {
      final added = await _service.addExerciseLog(exerciseLog);
      _exerciseLogs.insert(0, added);
      _dailySummary = await _service.getDailySummary(
        exerciseLog.userId,
        exerciseLog.timestamp,
        elderUserId: exerciseLog.userId,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete exercise log
  Future<bool> deleteExerciseLog(
    String logId,
    String userId, {
    String? elderUserId,
  }) async {
    try {
      await _service.deleteExerciseLog(logId, elderUserId: elderUserId);
      _exerciseLogs.removeWhere((e) => e.id == logId);
      _dailySummary = await _service.getDailySummary(
        userId,
        DateTime.now(),
        elderUserId: elderUserId,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get weekly summary
  Future<Map<String, dynamic>> getWeeklySummary(
    String userId, {
    String? elderUserId,
  }) async {
    return await _service.getWeeklySummary(userId, elderUserId: elderUserId);
  }

  // Fetch data for trends (last 30 days)
  Future<void> fetchTrendsData(String userId, {String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      _trendDietLogs = await _service.getDietLogs(
        userId,
        startDate: startDate,
        elderUserId: elderUserId,
      );
      _trendExerciseLogs = await _service.getExerciseLogs(
        userId,
        startDate: startDate,
        elderUserId: elderUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aggregate daily calorie data for trends
  Map<DateTime, Map<String, int>> getDailyCalorieData(int days) {
    final Map<DateTime, Map<String, int>> dailyData = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: days - 1));

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      dailyData[date] = {'in': 0, 'out': 0, 'net': 0};
    }

    for (var log in _trendDietLogs) {
      final pktDate = TimezoneUtil.toPakistanTime(log.timestamp);
      final date = DateTime(
        pktDate.year,
        pktDate.month,
        pktDate.day,
      );
      if (dailyData.containsKey(date)) {
        dailyData[date]!['in'] = (dailyData[date]!['in'] ?? 0) + log.calories;
      }
    }

    for (var log in _trendExerciseLogs) {
      final pktDate = TimezoneUtil.toPakistanTime(log.timestamp);
      final date = DateTime(
        pktDate.year,
        pktDate.month,
        pktDate.day,
      );
      if (dailyData.containsKey(date)) {
        dailyData[date]!['out'] =
            (dailyData[date]!['out'] ?? 0) + log.caloriesBurned;
      }
    }

    dailyData.forEach((date, data) {
      data['net'] = data['in']! - data['out']!;
    });

    return dailyData;
  }

  // Initialize mock data (deprecated - no longer needed with API integration)
  @Deprecated('Mock data initialization no longer supported')
  Future<void> initializeMockData(String userId) async {
    // Mock data initialization removed - data now comes from API
    await loadAll(userId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================
  // Diet Plan Methods
  // ============================================

  Future<void> loadDietPlans({String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _dietPlans = await _service.getDietPlans(elderUserId: elderUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DietPlanModel> createDietPlan(
    DietPlanModel plan, {
    String? elderUserId,
  }) async {
    try {
      final created = await _service.createDietPlan(
        plan,
        elderUserId: elderUserId,
      );
      _dietPlans.insert(0, created);
      _error = null;
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<DietPlanModel> updateDietPlan(
    String planId,
    DietPlanModel plan, {
    String? elderUserId,
  }) async {
    try {
      final updated = await _service.updateDietPlan(
        planId,
        plan,
        elderUserId: elderUserId,
      );
      final index = _dietPlans.indexWhere((p) => p.id == planId);
      if (index != -1) {
        _dietPlans[index] = updated;
      }
      _error = null;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteDietPlan(String planId, {String? elderUserId}) async {
    try {
      await _service.deleteDietPlan(planId, elderUserId: elderUserId);
      _dietPlans.removeWhere((p) => p.id == planId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> applyDietPlan(
    String planId,
    DateTime startDate,
    bool overwriteExisting, {
    String? elderUserId,
  }) async {
    try {
      final result = await _service.applyDietPlan(
        planId,
        startDate,
        overwriteExisting,
        elderUserId: elderUserId,
      );
      // Reload diet logs after applying plan
      if (elderUserId != null) {
        await loadDietLogs(
          elderUserId,
          date: startDate,
          elderUserId: elderUserId,
        );
      }
      _error = null;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ============================================
  // Exercise Plan Methods
  // ============================================

  Future<void> loadExercisePlans({String? elderUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _exercisePlans = await _service.getExercisePlans(
        elderUserId: elderUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ExercisePlanModel> createExercisePlan(
    ExercisePlanModel plan, {
    String? elderUserId,
  }) async {
    try {
      final created = await _service.createExercisePlan(
        plan,
        elderUserId: elderUserId,
      );
      _exercisePlans.insert(0, created);
      _error = null;
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<ExercisePlanModel> updateExercisePlan(
    String planId,
    ExercisePlanModel plan, {
    String? elderUserId,
  }) async {
    try {
      final updated = await _service.updateExercisePlan(
        planId,
        plan,
        elderUserId: elderUserId,
      );
      final index = _exercisePlans.indexWhere((p) => p.id == planId);
      if (index != -1) {
        _exercisePlans[index] = updated;
      }
      _error = null;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteExercisePlan(String planId, {String? elderUserId}) async {
    try {
      await _service.deleteExercisePlan(planId, elderUserId: elderUserId);
      _exercisePlans.removeWhere((p) => p.id == planId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> applyExercisePlan(
    String planId,
    DateTime startDate,
    bool overwriteExisting, {
    String? elderUserId,
  }) async {
    try {
      final result = await _service.applyExercisePlan(
        planId,
        startDate,
        overwriteExisting,
        elderUserId: elderUserId,
      );
      // Reload exercise logs after applying plan
      if (elderUserId != null) {
        await loadExerciseLogs(
          elderUserId,
          date: startDate,
          elderUserId: elderUserId,
        );
      }
      _error = null;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get diet plan compliance
  Future<Map<String, dynamic>> getDietPlanCompliance(
    String planId,
    DateTime startDate,
    DateTime endDate, {
    String? elderUserId,
  }) async {
    try {
      final result = await _service.getDietPlanCompliance(
        planId,
        startDate,
        endDate,
        elderUserId: elderUserId,
      );
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Get exercise plan compliance
  Future<Map<String, dynamic>> getExercisePlanCompliance(
    String planId,
    DateTime startDate,
    DateTime endDate, {
    String? elderUserId,
  }) async {
    try {
      final result = await _service.getExercisePlanCompliance(
        planId,
        startDate,
        endDate,
        elderUserId: elderUserId,
      );
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
