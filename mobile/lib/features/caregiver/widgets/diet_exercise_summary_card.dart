import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';

class DietExerciseSummaryCard extends StatelessWidget {
  final String elderId;

  const DietExerciseSummaryCard({super.key, required this.elderId});

  @override
  Widget build(BuildContext context) {
    final lifestyleProvider = context.watch<LifestyleProvider>();
    final dietLogs = lifestyleProvider.dietLogs;
    final exerciseLogs = lifestyleProvider.exerciseLogs;
    final dailySummary = lifestyleProvider.dailySummary;

    // Filter today's logs
    final today = DateTime.now();
    final todayDietLogs = dietLogs.where((log) {
      final logDate = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);
      return logDate.isAtSameMomentAs(todayDate);
    }).toList();

    final todayExerciseLogs = exerciseLogs.where((log) {
      final logDate = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);
      return logDate.isAtSameMomentAs(todayDate);
    }).toList();

    final mealsCount = todayDietLogs.length;
    final exerciseCount = todayExerciseLogs.length;
    final totalCalories = dailySummary?['totalCaloriesIn'] ?? 0;
    final totalExerciseMinutes = dailySummary?['totalExerciseMinutes'] ?? 0;

    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diet & Exercise Summary',
                style: ModernSurfaceTheme.sectionTitleStyle(context),
              ),
              TextButton(
                onPressed: () => context.push('/lifestyle'),
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.restaurant,
                  label: 'Meals',
                  value: '$mealsCount',
                  color: ModernSurfaceTheme.accentCoral,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.fitness_center,
                  label: 'Exercises',
                  value: '$exerciseCount',
                  color: ModernSurfaceTheme.accentBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '${totalCalories.toStringAsFixed(0)}',
                  color: ModernSurfaceTheme.accentYellow,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.timer,
                  label: 'Exercise',
                  value: '${totalExerciseMinutes}min',
                  color: ModernSurfaceTheme.primaryTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
