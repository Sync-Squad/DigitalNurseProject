import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/extensions/meal_type_extensions.dart';
import '../../../core/extensions/activity_type_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/utils/timezone_util.dart';
import 'expandable_section_tile.dart';

class DietExerciseSection extends StatelessWidget {
  const DietExerciseSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LifestyleProvider>(
      builder: (context, lifestyleProvider, child) {
        final now = TimezoneUtil.nowInPakistan();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        // Get today's diet and exercise logs
        final todayDietLogs = lifestyleProvider.dietLogs.where((log) {
          return log.timestamp.isAfter(todayStart) &&
              log.timestamp.isBefore(todayEnd);
        }).toList();

        final todayExerciseLogs = lifestyleProvider.exerciseLogs.where((log) {
          return log.timestamp.isAfter(todayStart) &&
              log.timestamp.isBefore(todayEnd);
        }).toList();

        final todayTotalLogs = todayDietLogs.length + todayExerciseLogs.length;

        return ExpandableSectionTile(
          icon: Icons.directions_run, // Person running/exercising icon
          title: 'dashboard.dietExercise'.tr(),
          subtitle: 'dashboard.viewDetailsTitle'.tr(),
          count: '$todayTotalLogs',
          titleColor: context.theme.colors.primary,
          routeForViewDetails: '/lifestyle',
          interactionMode: InteractionMode.standard,
          expandedChild: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayTotalLogs == 0) ...[
                  Center(
                    child: Text(
                      'dashboard.noDietExercise'.tr(),
                      style: TextStyle(
                        color: ModernSurfaceTheme.deepTeal.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'dashboard.todaysActivity'.tr(),
                    style: ModernSurfaceTheme.sectionTitleStyle(context),
                  ),
                  const SizedBox(height: 12),

                  // Diet logs
                  if (todayDietLogs.isNotEmpty) ...[
                    Text(
                      'dashboard.meals'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getSuccessColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...todayDietLogs.take(2).map((log) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: ModernSurfaceTheme.tintedCard(
                            context,
                            AppTheme.getSuccessColor(context),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: AppTheme.getSuccessColor(context),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            log.mealType.displayName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        if (log.sourcePlanId != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.getSuccessColor(
                                                context,
                                              ).withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  FIcons.calendar,
                                                  size: 10,
                                                  color:
                                                      AppTheme.getSuccessColor(
                                                        context,
                                                      ),
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Plan',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            AppTheme.getSuccessColor(
                                                              context,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 9,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      log.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context
                                                .theme
                                                .colors
                                                .mutedForeground,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${log.calories} cal',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.getSuccessColor(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Exercise logs
                  if (todayExerciseLogs.isNotEmpty) ...[
                    Text(
                      'dashboard.exercise'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ModernSurfaceTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...todayExerciseLogs.take(2).map((log) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: ModernSurfaceTheme.tintedCard(
                            context,
                            ModernSurfaceTheme.accentBlue,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: context.theme.colors.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            log.activityType.displayName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        if (log.sourcePlanId != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ModernSurfaceTheme
                                                  .accentBlue
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  FIcons.calendar,
                                                  size: 10,
                                                  color: ModernSurfaceTheme
                                                      .accentBlue,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Plan',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            ModernSurfaceTheme
                                                                .accentBlue,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 9,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      log.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context
                                                .theme
                                                .colors
                                                .mutedForeground,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${log.durationMinutes}m',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.theme.colors.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    '${log.caloriesBurned} cal',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.theme.colors.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  if (todayTotalLogs > 4) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'dashboard.moreActivities'.tr(
                          namedArgs: {'count': '${todayTotalLogs - 4}'},
                        ),
                        style: TextStyle(
                          color: ModernSurfaceTheme.deepTeal.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
