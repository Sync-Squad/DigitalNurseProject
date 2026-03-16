import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/extensions/meal_type_extensions.dart';
import '../../../core/extensions/activity_type_extensions.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_util.dart';
import '../../../core/widgets/horizontal_modern_calendar.dart';
import '../../../core/widgets/modern_scaffold.dart';

class DietExerciseLogScreen extends StatefulWidget {
  const DietExerciseLogScreen({super.key});

  @override
  State<DietExerciseLogScreen> createState() => _DietExerciseLogScreenState();
}

class _DietExerciseLogScreenState extends State<DietExerciseLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = TimezoneUtil.nowInPakistan();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogsForDate(_selectedDate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogsForDate(DateTime date) async {
    final lifestyleProvider = context.read<LifestyleProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      String? elderUserId;
      String? targetUserId = user.id;

      if (user.role == UserRole.caregiver) {
        final careContext = context.read<CareContextProvider>();
        await careContext.ensureLoaded();
        if (!mounted) return;
        targetUserId = careContext.selectedElderId ?? user.id;
        elderUserId = targetUserId;
      }

      await lifestyleProvider.loadAll(
        targetUserId,
        date: date,
        elderUserId: elderUserId,
      );
    }
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadLogsForDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final lifestyleProvider = context.watch<LifestyleProvider>();
    final summary = lifestyleProvider.dailySummary;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Diet & Exercise',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
            tooltip: 'Trends',
            onPressed: () => context.push('/lifestyle/trends'),
          ),
        ],
      ),
      body: Padding(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Column(
          children: [
            // Calendar
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: ModernSurfaceTheme.glassCard(
                context,
                accent: ModernSurfaceTheme.primaryTeal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Activity',
                    style: ModernSurfaceTheme.sectionTitleStyle(context),
                  ),
                  SizedBox(height: 12.h),
                  HorizontalModernCalendar(
                    selectedDate: _selectedDate,
                    onDateChanged: _handleDateChanged,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Daily summary
            _DailySummaryCard(
              summary: summary,
              isLoading: lifestyleProvider.isLoading,
            ),
            SizedBox(height: 16.h),

            // Tab bar
            Container(
              decoration: ModernSurfaceTheme.glassCard(context),
              margin: EdgeInsets.only(bottom: 16.h),
              child: TabBar(
                controller: _tabController,
                indicatorColor: ModernSurfaceTheme.primaryTeal,
                labelColor: ModernSurfaceTheme.primaryTeal,
                unselectedLabelColor: ModernSurfaceTheme.deepTeal.withValues(
                  alpha: 0.5,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Meals'),
                  Tab(text: 'Workouts'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MealsTab(selectedDate: _selectedDate),
                  _WorkoutsTab(selectedDate: _selectedDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealsTab extends StatefulWidget {
  final DateTime selectedDate;

  const _MealsTab({required this.selectedDate});

  @override
  State<_MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<_MealsTab> {
  String? _deletingMealId;

  Future<void> _handleDeleteMeal(BuildContext context, String mealId) async {
    if (_deletingMealId != null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      setState(() {
        _deletingMealId = mealId;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        if (user == null) {
          return;
        }

        // Handle caregiver context
        String? elderUserId;
        String? targetUserId = user.id;
        if (user.role == UserRole.caregiver) {
          final careContext = context.read<CareContextProvider>();
          await careContext.ensureLoaded();
          targetUserId = careContext.selectedElderId ?? user.id;
          elderUserId = targetUserId;
        }

        final lifestyleProvider = context.read<LifestyleProvider>();
        final success = await lifestyleProvider.deleteDietLog(
          mealId,
          targetUserId,
          elderUserId: elderUserId,
        );

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Meal deleted successfully'),
                backgroundColor: AppTheme.getSuccessColor(context),
              ),
            );
            // Reload logs for the selected date
            await lifestyleProvider.loadAll(
              targetUserId,
              date: widget.selectedDate,
              elderUserId: elderUserId,
            );
          } else {
            final errorMessage =
                lifestyleProvider.error ??
                'Failed to delete meal. Please try again.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppTheme.getErrorColor(context),
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _deletingMealId = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lifestyleProvider = context.watch<LifestyleProvider>();
    final isLoading = lifestyleProvider.isLoading;
    final meals = lifestyleProvider.dietLogs;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final dateStr =
                      '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';
                  context.push('/lifestyle/meal/add?selectedDate=$dateStr');
                },
                icon: const Icon(FIcons.plus),
                label: const Text('Add Meal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appleGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            ElevatedButton.icon(
              onPressed: () => context.push('/lifestyle/plans'),
              icon: const Icon(FIcons.calendar),
              label: const Text('Plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ModernSurfaceTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: ModernSurfaceTheme.primaryTeal,
                  ),
                )
              : meals.isEmpty
                  ? _buildEmptyState(
                  context,
                  icon: FIcons.utensils,
                  title: 'No meals logged today',
                  message: 'Tap the button above to add your first meal',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                )
              : ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Container(
                        decoration: ModernSurfaceTheme.glassCard(
                          context,
                          accent: ModernSurfaceTheme.primaryTeal,
                        ),
                        padding: ModernSurfaceTheme.cardPadding(),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: ModernSurfaceTheme.iconBadge(
                                context,
                                ModernSurfaceTheme.primaryTeal,
                              ),
                              child: const Icon(
                                FIcons.utensils,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          meal.mealType.displayName,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (meal.sourcePlanId != null)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ModernSurfaceTheme
                                                .primaryTeal
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                FIcons.calendar,
                                                size: 12,
                                                color: ModernSurfaceTheme
                                                    .primaryTeal,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Plan',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: ModernSurfaceTheme
                                                          .primaryTeal,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    meal.description,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(
                                      TimezoneUtil.toPakistanTime(
                                        meal.timestamp,
                                      ),
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${meal.calories}',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ModernSurfaceTheme.primaryTeal,
                                  ),
                                ),
                                Text(
                                  'cal',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 8.w),
                            _deletingMealId == meal.id
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    onPressed: _deletingMealId != null
                                        ? null
                                        : () => _handleDeleteMeal(
                                            context,
                                            meal.id,
                                          ),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.getErrorColor(context),
                                    ),
                                    tooltip: 'Delete meal',
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colorScheme.primary),
          SizedBox(height: 12.h),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutsTab extends StatefulWidget {
  final DateTime selectedDate;

  const _WorkoutsTab({required this.selectedDate});

  @override
  State<_WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<_WorkoutsTab> {
  String? _deletingWorkoutId;

  Future<void> _handleDeleteWorkout(
    BuildContext context,
    String workoutId,
  ) async {
    if (_deletingWorkoutId != null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      setState(() {
        _deletingWorkoutId = workoutId;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        if (user == null) {
          return;
        }

        // Handle caregiver context
        String? elderUserId;
        String? targetUserId = user.id;
        if (user.role == UserRole.caregiver) {
          final careContext = context.read<CareContextProvider>();
          await careContext.ensureLoaded();
          targetUserId = careContext.selectedElderId ?? user.id;
          elderUserId = targetUserId;
        }

        final lifestyleProvider = context.read<LifestyleProvider>();
        final success = await lifestyleProvider.deleteExerciseLog(
          workoutId,
          targetUserId,
          elderUserId: elderUserId,
        );

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Workout deleted successfully'),
                backgroundColor: AppTheme.getSuccessColor(context),
              ),
            );
            // Reload logs for the selected date
            await lifestyleProvider.loadAll(
              targetUserId,
              date: widget.selectedDate,
              elderUserId: elderUserId,
            );
          } else {
            final errorMessage =
                lifestyleProvider.error ??
                'Failed to delete workout. Please try again.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppTheme.getErrorColor(context),
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _deletingWorkoutId = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lifestyleProvider = context.watch<LifestyleProvider>();
    final isLoading = lifestyleProvider.isLoading;
    final workouts = lifestyleProvider.exerciseLogs;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final dateStr =
                      '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';
                  context.push('/lifestyle/workout/add?selectedDate=$dateStr');
                },
                icon: const Icon(FIcons.plus),
                label: const Text('Add Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appleGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            ElevatedButton.icon(
              onPressed: () => context.push('/lifestyle/plans'),
              icon: const Icon(FIcons.calendar),
              label: const Text('Plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ModernSurfaceTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: ModernSurfaceTheme.accentBlue,
                  ),
                )
              : workouts.isEmpty
                  ? _buildEmptyState(
                  context,
                  icon: FIcons.activity,
                  title: 'No workouts logged today',
                  message: 'Tap the button above to add your first workout',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                )
              : ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Container(
                        decoration: ModernSurfaceTheme.glassCard(
                          context,
                          accent: ModernSurfaceTheme.accentBlue,
                        ),
                        padding: ModernSurfaceTheme.cardPadding(),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: ModernSurfaceTheme.iconBadge(
                                context,
                                ModernSurfaceTheme.accentBlue,
                              ),
                              child: const Icon(
                                FIcons.activity,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          workout.activityType.displayName,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (workout.sourcePlanId != null)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ModernSurfaceTheme.accentBlue
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                FIcons.calendar,
                                                size: 12,
                                                color: ModernSurfaceTheme
                                                    .accentBlue,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Plan',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: ModernSurfaceTheme
                                                          .accentBlue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    workout.description,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${workout.durationMinutes} min • ${DateFormat('MMM d, yyyy').format(TimezoneUtil.toPakistanTime(workout.timestamp))}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${workout.caloriesBurned}',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ModernSurfaceTheme.accentBlue,
                                  ),
                                ),
                                Text(
                                  'cal',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 8.w),
                            _deletingWorkoutId == workout.id
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    onPressed: _deletingWorkoutId != null
                                        ? null
                                        : () => _handleDeleteWorkout(
                                            context,
                                            workout.id,
                                          ),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.getErrorColor(context),
                                    ),
                                    tooltip: 'Delete workout',
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colorScheme.primary),
          SizedBox(height: 12.h),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final bool isLoading;

  const _DailySummaryCard({this.summary, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      height: 140.h, // Fixed height to prevent jump when loading
      decoration: ModernSurfaceTheme.heroDecoration(context),
      padding: ModernSurfaceTheme.heroPadding(),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : summary == null
              ? Center(
                  child: Text(
                    'No summary available',
                    style: textTheme.bodyMedium?.copyWith(color: onPrimary),
                  ),
                )
              : Row(
                  children: [
                    _SummaryMetric(
                      icon: FIcons.utensils,
                      label: 'Calories In',
                      value: '${summary!['caloriesIn']}',
                      onPrimary: onPrimary,
                      textTheme: textTheme,
                    ),
                    _SummaryMetric(
                      icon: FIcons.activity,
                      label: 'Calories Out',
                      value: '${summary!['caloriesOut']}',
                      onPrimary: onPrimary,
                      textTheme: textTheme,
                    ),
                    _SummaryMetric(
                      icon: FIcons.trendingUp,
                      label: 'Net',
                      value: '${summary!['netCalories']}',
                      onPrimary: onPrimary,
                      textTheme: textTheme,
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
  final Color onPrimary;
  final TextTheme textTheme;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPrimary,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: onPrimary),
          SizedBox(height: 8.h),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: onPrimary.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
