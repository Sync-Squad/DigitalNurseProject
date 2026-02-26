import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/extensions/vital_type_extensions.dart';
import '../../../core/extensions/vital_status_extensions.dart';
import '../../../core/models/vital_measurement_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/models/user_model.dart';
import '../widgets/vitals_calendar_header.dart';
import '../widgets/vital_status_badge.dart';

class VitalsListScreen extends StatefulWidget {
  const VitalsListScreen({super.key});

  @override
  State<VitalsListScreen> createState() => _VitalsListScreenState();
}

class _VitalsListScreenState extends State<VitalsListScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _lastContextKey;
  String? _deletingVitalId;

  Future<void> _reloadVitals() async {
    final authProvider = context.read<AuthProvider>();
    final healthProvider = context.read<HealthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return;
    }

    final isCaregiver = user.role == UserRole.caregiver;
    String? targetUserId = user.id;
    String? elderUserId;

    if (isCaregiver) {
      final careContext = context.read<CareContextProvider>();
      await careContext.ensureLoaded();
      targetUserId = careContext.selectedElderId;
      elderUserId = targetUserId;
      if (targetUserId == null) {
        return;
      }
    }

    await healthProvider.loadVitals(targetUserId, elderUserId: elderUserId);
  }

  void _ensureContextSync({
    required bool isCaregiver,
    required String? selectedElderId,
    required String? userId,
  }) {
    final key = isCaregiver
        ? 'caregiver-${selectedElderId ?? 'none'}'
        : 'patient-${userId ?? 'unknown'}';

    if (_lastContextKey == key) {
      return;
    }

    _lastContextKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reloadVitals();
      }
    });
  }

  Future<void> _handleDeleteVital(
    String vitalId,
    bool isCaregiver,
    String? selectedElderId,
  ) async {
    if (_deletingVitalId != null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vital Measurement'),
        content: const Text(
          'Are you sure you want to delete this vital measurement?',
        ),
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

    if (confirm == true && mounted) {
      setState(() {
        _deletingVitalId = vitalId;
      });

      try {
        final healthProvider = context.read<HealthProvider>();
        final success = await healthProvider.deleteVital(
          vitalId,
          elderUserId: isCaregiver ? selectedElderId : null,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Vital measurement deleted successfully'),
                backgroundColor: AppTheme.getSuccessColor(context),
              ),
            );
            // Reload vitals to refresh the list
            await _reloadVitals();
          } else {
            final errorMessage =
                healthProvider.error ?? 'Failed to delete vital measurement';
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
            _deletingVitalId = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isCaregiver = currentUser?.role == UserRole.caregiver;
    final careContext = isCaregiver
        ? context.watch<CareContextProvider>()
        : null;
    final selectedElderId = careContext?.selectedElderId;
    final hasAssignments =
        !isCaregiver || (careContext?.careRecipients.isNotEmpty ?? false);
    final isCareContextLoading = careContext?.isLoading ?? false;
    final careContextError = careContext?.error;

    _ensureContextSync(
      isCaregiver: isCaregiver,
      selectedElderId: selectedElderId,
      userId: currentUser?.id,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final healthProvider = context.watch<HealthProvider>();
    final vitals = healthProvider.getVitalsForDate(_selectedDate);
    final error = healthProvider.error;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onPrimary,
        iconTheme: IconThemeData(color: onPrimary),
        title: Text(
          'Health Vitals',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!isCaregiver)
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: onPrimary),
              onPressed: () => context.push('/vitals/add'),
            ),
        ],
      ),
      body: _buildBody(
        context,
        isCaregiver: isCaregiver,
        hasAssignments: hasAssignments,
        hasSelectedRecipient: selectedElderId != null,
        isCareContextLoading: isCareContextLoading,
        careContextError: careContextError,
        healthProvider: healthProvider,
        vitals: vitals,
        error: error,
        selectedElderId: selectedElderId,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isCaregiver,
    required bool hasAssignments,
    required bool hasSelectedRecipient,
    required bool isCareContextLoading,
    required String? careContextError,
    required HealthProvider healthProvider,
    required List<VitalMeasurementModel> vitals,
    required String? error,
    required String? selectedElderId,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final onPrimary = colorScheme.onPrimary;

    if (isCaregiver) {
      if (isCareContextLoading && !hasAssignments) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!hasAssignments) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.users,
          title: 'No patients assigned yet',
          message:
              'Once you are added as a caregiver, you can review vitals for your patients here.',
        );
      }

      if (careContextError != null && !hasSelectedRecipient) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.info,
          title: 'Unable to load patients',
          message: careContextError,
          onRetry: _reloadVitals,
        );
      }

      if (!hasSelectedRecipient) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.userSearch,
          title: 'Select a patient to continue',
          message:
              'Choose a patient from the dashboard to review their latest vitals.',
        );
      }
    }

    if (healthProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final normalCount = vitals
        .where((v) => v.getHealthStatus() == VitalHealthStatus.normal)
        .length;
    final warningCount = vitals
        .where((v) => v.getHealthStatus() != VitalHealthStatus.normal)
        .length;

    return Padding(
      padding: ModernSurfaceTheme.screenPadding(),
      child: Column(
        children: [
          _VitalsHero(
            totalCount: vitals.length,
            normalCount: normalCount,
            warningCount: warningCount,
            dateLabel: _getFormattedDate(_selectedDate),
            isCaregiver: isCaregiver,
          ),
          if (error != null) ...[
            SizedBox(height: 16.h),
            _ErrorBanner(message: error, onRetry: _reloadVitals),
          ],
          SizedBox(height: 16.h),
          VitalsCalendarHeader(
            selectedDate: _selectedDate,
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            decoration: ModernSurfaceTheme.glassCard(context),
            padding: EdgeInsets.all(16.w),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/health/trends'),
              icon: Icon(FIcons.trendingUp, color: Colors.white),
              label: Text(
                'View Trends',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: AppTheme.appleGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: vitals.isEmpty
                ? _buildEmptyState(context, isCaregiver: isCaregiver)
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: vitals.length,
                    itemBuilder: (context, index) {
                      final vital = vitals[index];
                      final healthStatus = vital.getHealthStatus();
                      final accent = _getStatusColor(healthStatus);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: ModernSurfaceTheme.glassCard(
                            context,
                            accent: accent,
                          ),
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: ModernSurfaceTheme.iconBadge(
                                      context,
                                      accent,
                                    ),
                                    child: Icon(
                                      FIcons.activity,
                                      color: onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vital.type.displayName,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: onSurface,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'MMM d, yyyy - h:mm a',
                                          ).format(vital.timestamp),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: muted,
                                          ),
                                        ),
                                        if (vital.notes != null) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            vital.notes!,
                                            style: textTheme.bodySmall
                                                ?.copyWith(color: muted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        vital.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: accent,
                                            ),
                                      ),
                                      Text(
                                        vital.type.unit,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 8.w),
                                  _deletingVitalId == vital.id
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
                                          onPressed: _deletingVitalId != null
                                              ? null
                                              : () => _handleDeleteVital(
                                                  vital.id,
                                                  isCaregiver,
                                                  selectedElderId,
                                                ),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.getErrorColor(
                                              context,
                                            ),
                                          ),
                                          tooltip: 'Delete vital measurement',
                                        ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              VitalStatusBadge(
                                status: healthStatus,
                                vital: vital,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isCaregiver}) {
    final healthProvider = context.watch<HealthProvider>();
    final allVitals = healthProvider.vitals;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final onPrimary = colorScheme.onPrimary;

    if (allVitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FIcons.activity, size: 64.r, color: colorScheme.primary),
            SizedBox(height: 16.h),
            Text(
              'No vitals logged yet',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isCaregiver
                  ? 'This patient has no vitals recorded yet.'
                  : 'Start tracking your health vitals',
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (!isCaregiver) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => context.push('/vitals/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Log Vitals',
                  style: textTheme.labelLarge?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FIcons.calendar, size: 64.r, color: colorScheme.primary),
            SizedBox(height: 16.h),
            Text(
              'No vitals for ${_getFormattedDate(_selectedDate)}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Select another date or add vitals',
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      );
    }
  }

  String _getFormattedDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getStatusColor(VitalHealthStatus status) {
    return status.getStatusColor(context);
  }

  Widget _buildCaregiverNotice(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colorScheme.primary),
          SizedBox(height: 16.h),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: onPrimary,
              ),
              child: Text(
                'Retry',
                style: textTheme.labelLarge?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getErrorColor(context);
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context, accent: color),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(FIcons.info, color: color),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: color),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _VitalsHero extends StatelessWidget {
  final int totalCount;
  final int normalCount;
  final int warningCount;
  final String dateLabel;
  final bool isCaregiver;

  const _VitalsHero({
    required this.totalCount,
    required this.normalCount,
    required this.warningCount,
    required this.dateLabel,
    required this.isCaregiver,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      decoration: ModernSurfaceTheme.heroDecoration(context),
      padding: ModernSurfaceTheme.heroPadding(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Right-side illustration
          Positioned(
            right: -16,
            bottom: -16,
            child: Image.asset(
              'images/health.png',
              width: 190.w,
              height: 190.h,
              fit: BoxFit.contain,
            ),
          ),
          // Left-side content
          Padding(
            padding: EdgeInsets.only(right: 110.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCaregiver
                      ? 'Patient vitals overview'
                      : 'Today\u2019s vitals snapshot',
                  style: textTheme.bodyMedium?.copyWith(
                    color: onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.appleGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalCount',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Checks on $dateLabel',
                        style: textTheme.headlineSmall?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _HeroChip(
                      icon: Icons.favorite,
                      label: '$normalCount stable',
                    ),
                    _HeroChip(
                      icon: Icons.warning_amber_rounded,
                      label: '$warningCount needs attention',
                    ),
                    if (!isCaregiver)
                      _HeroChip(
                        icon: Icons.add_circle_outline,
                        label: 'Log Vital',
                        onTap: () => context.push('/vitals/add'),
                      ),
                  ],
                ), // Wrap
              ],
            ), // Column
          ), // Padding
        ],
      ), // Stack
    ); // Container
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeroChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppTheme.appleGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }
}
