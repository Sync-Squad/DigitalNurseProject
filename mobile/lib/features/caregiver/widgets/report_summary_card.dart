import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';

class ReportSummaryCard extends StatelessWidget {
  final String elderId;
  final String period; // 'weekly' or 'monthly'

  const ReportSummaryCard({
    super.key,
    required this.elderId,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final medicationProvider = context.watch<MedicationProvider>();
    final lifestyleProvider = context.watch<LifestyleProvider>();

    final adherence = medicationProvider.adherencePercentage;
    final abnormalVitals = healthProvider.vitals
        .where((v) => v.isAbnormal())
        .length;
    final dailySummary = lifestyleProvider.dailySummary ?? {};
    final totalCalories = dailySummary['totalCaloriesIn'] ?? 0;
    final totalExercise = dailySummary['totalExerciseMinutes'] ?? 0;

    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context, highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${period[0].toUpperCase()}${period.substring(1)} Summary',
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Adherence',
                  value: '${adherence.toStringAsFixed(0)}%',
                  color: adherence >= 90
                      ? AppTheme.getSuccessColor(context)
                      : adherence >= 75
                      ? AppTheme.getWarningColor(context)
                      : AppTheme.getErrorColor(context),
                  icon: Icons.medication,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _MetricCard(
                  label: 'Alerts',
                  value: '$abnormalVitals',
                  color: abnormalVitals == 0
                      ? AppTheme.getSuccessColor(context)
                      : AppTheme.getErrorColor(context),
                  icon: Icons.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Calories',
                  value: '${totalCalories.toStringAsFixed(0)}',
                  color: ModernSurfaceTheme.accentYellow,
                  icon: Icons.local_fire_department,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _MetricCard(
                  label: 'Exercise',
                  value: '${totalExercise}min',
                  color: ModernSurfaceTheme.accentBlue,
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
