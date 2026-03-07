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
import '../../../core/models/user_model.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../widgets/vital_status_badge.dart';

class AbnormalVitalsScreen extends StatefulWidget {
  const AbnormalVitalsScreen({super.key});

  @override
  State<AbnormalVitalsScreen> createState() => _AbnormalVitalsScreenState();
}

class _AbnormalVitalsScreenState extends State<AbnormalVitalsScreen> {
  String? _lastContextKey;

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

  Map<String, List<VitalMeasurementModel>> _groupVitalsByDate(
    List<VitalMeasurementModel> vitals,
  ) {
    final grouped = <String, List<VitalMeasurementModel>>{};
    for (final vital in vitals) {
      final dateKey = DateFormat('yyyy-MM-dd').format(vital.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(vital);
    }

    // Sort dates in descending order (most recent first)
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final sortedGrouped = <String, List<VitalMeasurementModel>>{};
    for (final date in sortedDates) {
      final dateVitals = grouped[date]!;
      // Sort vitals within each date by timestamp (most recent first)
      dateVitals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      sortedGrouped[date] = dateVitals;
    }

    return sortedGrouped;
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
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

    final healthProvider = context.watch<HealthProvider>();
    final allVitals = healthProvider.vitals;
    final abnormalVitals = allVitals
        .where((vital) => vital.isAbnormal())
        .toList();
    final groupedVitals = _groupVitalsByDate(abnormalVitals);
    final error = healthProvider.error;

    return ModernScaffold(
      safeAreaTop: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF66B2B2),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(FIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Abnormal Vitals',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: _buildBody(
        context,
        isCaregiver: isCaregiver,
        hasAssignments: hasAssignments,
        hasSelectedRecipient: selectedElderId != null,
        isCareContextLoading: isCareContextLoading,
        careContextError: careContextError,
        healthProvider: healthProvider,
        groupedVitals: groupedVitals,
        abnormalVitals: abnormalVitals,
        error: error,
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
    required Map<String, List<VitalMeasurementModel>> groupedVitals,
    required List<VitalMeasurementModel> abnormalVitals,
    required String? error,
  }) {
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

    return Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ErrorBanner(message: error, onRetry: _reloadVitals),
          ),
        // Stats header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF66B2B2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '${abnormalVitals.length} abnormal ${abnormalVitals.length == 1 ? 'vital' : 'vitals'}',
                  style: context.theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Vitals list or empty state
        Expanded(
          child: abnormalVitals.isEmpty
              ? _buildEmptyState(context, isCaregiver: isCaregiver)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groupedVitals.length,
                  itemBuilder: (context, dateIndex) {
                    final dateKey = groupedVitals.keys.elementAt(dateIndex);
                    final dateVitals = groupedVitals[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: EdgeInsets.only(
                            top: dateIndex > 0 ? 24.h : 8.h,
                            bottom: 12.h,
                          ),
                          child: Text(
                            _formatDateHeader(dateKey).toUpperCase(),
                            style: context.theme.typography.xs.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        // Vitals for this date
                        ...dateVitals.map((vital) {
                          final healthStatus = vital.getHealthStatus();
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF66B2B2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(healthStatus)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            FIcons.activity,
                                            color: _getStatusColor(
                                              healthStatus,
                                            ),
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
                                                style: context
                                                    .theme
                                                    .typography
                                                    .base
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat(
                                                  'h:mm a',
                                                ).format(vital.timestamp),
                                                style: context
                                                    .theme.typography.sm
                                                    .copyWith(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              if (vital.notes != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  vital.notes!,
                                                  style: context
                                                      .theme
                                                      .typography
                                                      .xs
                                                      .copyWith(
                                                        color: Colors.white60,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              vital.value,
                                              style: context.theme.typography.lg
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(
                                                      healthStatus,
                                                    ),
                                                  ),
                                            ),
                                            Text(
                                              vital.type.unit,
                                              style: context.theme.typography.xs
                                                  .copyWith(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
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
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isCaregiver}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64.r,
            color: AppTheme.getSuccessColor(context),
          ),
          SizedBox(height: 16.h),
          Text(
            'No abnormal vitals',
            style: context.theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isCaregiver
                ? 'All vitals for this patient are within normal range.'
                : 'All your vitals are within normal range.',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: context.theme.colors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: context.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FButton(onPress: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getErrorColor(context).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getErrorColor(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(FIcons.info, color: AppTheme.getErrorColor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.theme.typography.sm.copyWith(
                color: AppTheme.getErrorColor(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
