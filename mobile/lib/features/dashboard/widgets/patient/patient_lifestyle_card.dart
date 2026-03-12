import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/extensions/activity_type_extensions.dart';
import '../../../../core/extensions/meal_type_extensions.dart';
import '../../../../core/providers/lifestyle_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_util.dart';
import '../dashboard_theme.dart';
import 'expandable_patient_card.dart';

class PatientLifestyleCard extends StatelessWidget {
  const PatientLifestyleCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final lifestyleProvider = context.watch<LifestyleProvider>();
    final now = TimezoneUtil.nowInPakistan();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayDietLogs = lifestyleProvider.dietLogs.where((log) {
      final pktTime = TimezoneUtil.toPakistanTime(log.timestamp);
      final logDate = DateTime(pktTime.year, pktTime.month, pktTime.day);
      return logDate.isAtSameMomentAs(todayStart);
    }).toList();

    final todayExerciseLogs = lifestyleProvider.exerciseLogs.where((log) {
      final pktTime = TimezoneUtil.toPakistanTime(log.timestamp);
      final logDate = DateTime(pktTime.year, pktTime.month, pktTime.day);
      return logDate.isAtSameMomentAs(todayStart);
    }).toList();

    final todayTotalLogs = todayDietLogs.length + todayExerciseLogs.length;

    final brightness = Theme.of(context).brightness;

    return ExpandablePatientCard(
      icon: Icons.directions_run_outlined,
      title: 'patient.yourLifestyle'.tr(),
      subtitle: 'patient.lifestyleSubtitle'.tr(),
      count: '$todayTotalLogs',
      accentColor: CaregiverDashboardTheme.accentBlue,
      routeForViewDetails: '/lifestyle',
      expandedChild: todayTotalLogs == 0
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: CaregiverDashboardTheme.tintedCard(
                context,
                CaregiverDashboardTheme.primaryTeal,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: CaregiverDashboardTheme.iconBadge(
                      context,
                      CaregiverDashboardTheme.primaryTeal,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'patient.noLifestyleLogs'.tr(),
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CaregiverDashboardTheme.tintedForegroundColor(
                          CaregiverDashboardTheme.primaryTeal,
                          brightness: brightness,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayDietLogs.isNotEmpty) ...[
                  Text(
                    'patient.meals'.tr(),
                    style: context.theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CaregiverDashboardTheme.deepTeal,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...todayDietLogs.take(2).map((log) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _LifestyleLogRow(
                        icon: Icons.restaurant,
                        title: log.mealType.displayName,
                        subtitle: log.description,
                        value: '${log.calories} cal',
                        accent: AppTheme.getSuccessColor(context),
                        onTap: () => context.push('/lifestyle'),
                      ),
                    );
                  }),
                  if (todayDietLogs.length > 2) SizedBox(height: 12.h),
                ],
                if (todayExerciseLogs.isNotEmpty) ...[
                  Text(
                    'patient.exercise'.tr(),
                    style: context.theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CaregiverDashboardTheme.deepTeal,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...todayExerciseLogs.take(2).map((log) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _LifestyleLogRow(
                        icon: Icons.fitness_center,
                        title: log.activityType.displayName,
                        subtitle:
                            '${log.durationMinutes} min, ${log.caloriesBurned} cal',
                        value: '${log.durationMinutes} min',
                        accent: context.theme.colors.secondary,
                        onTap: () => context.push('/lifestyle'),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}

class _LifestyleLogRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  const _LifestyleLogRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final onTint = CaregiverDashboardTheme.tintedForegroundColor(
      accent,
      brightness: brightness,
    );
    final onTintMuted = CaregiverDashboardTheme.tintedMutedColor(
      accent,
      brightness: brightness,
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: CaregiverDashboardTheme.tintedCard(context, accent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: CaregiverDashboardTheme.iconBadge(context, accent),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onTint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: context.theme.typography.xs.copyWith(
                    color: onTintMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              textStyle: context.theme.typography.xs.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
