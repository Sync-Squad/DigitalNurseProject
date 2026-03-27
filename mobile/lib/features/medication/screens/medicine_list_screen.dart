import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/timezone_util.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/medicine_model.dart';
import '../widgets/medicine_calendar_header.dart';
import '../widgets/medicine_schedule_card.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen>
    with WidgetsBindingObserver {
  DateTime _selectedDate = TimezoneUtil.nowInPakistan();
  String? _lastContextKey;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer data loading until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentTabIndex = context.read<int>();
        if (currentTabIndex == 1) {
          _loadMedicines();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      setState(() {
        _refreshKey++;
      });
    }
  }

  Future<void> _loadMedicines() async {
    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
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

    await medicationProvider.loadMedicines(
      targetUserId,
      elderUserId: elderUserId,
      includeExtras: false,
    );

    // Intake history call removed as requested by user to optimize performance
  }

  bool _wasVisible = false;

  void _ensureContextSync({
    required bool isCaregiver,
    required String? selectedElderId,
    required String? userId,
    required bool isVisible,
  }) {
    final key = isCaregiver
        ? 'caregiver-${selectedElderId ?? 'none'}'
        : 'patient-${userId ?? 'unknown'}';

    final contextChanged = _lastContextKey != key;
    final visibilityChanged = !_wasVisible && isVisible;

    if (!contextChanged && !visibilityChanged) {
      return;
    }

    _lastContextKey = key;
    _wasVisible = isVisible;

    if (isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadMedicines();
        }
      });
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

    final currentTabIndex = context.watch<int>();
    final isVisible = currentTabIndex == 1;

    _ensureContextSync(
      isCaregiver: isCaregiver,
      selectedElderId: selectedElderId,
      userId: currentUser?.id,
      isVisible: isVisible,
    );

    final medicationProvider = context.watch<MedicationProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;
    final medicines = medicationProvider.medicines;
    final errorMessage = medicationProvider.error;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'medication.title'.tr(),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: onPrimary,
              ),
            ),
            if (isCaregiver && careContext?.selectedRecipient != null)
              Text(
                'medication.forPatient'.tr(namedArgs: {'name': careContext!.selectedRecipient!.name}),
                style: textTheme.bodySmall?.copyWith(
                  color: onPrimary.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: onPrimary),
            onPressed: () => context.push('/medicine/log'),
            tooltip: 'medication.history.title'.tr(),
          ),
          if (!isCaregiver)
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: onPrimary),
              onPressed: () => context.push('/medicine/add'),
            ),
        ],
      ),
      body: Padding(
        padding: ModernSurfaceTheme.screenPadding(),
        child: _buildBody(
          context,
          medicationProvider: medicationProvider,
          medicines: medicines,
          errorMessage: errorMessage,
          isCaregiver: isCaregiver,
          hasAssignments: hasAssignments,
          isCareContextLoading: isCareContextLoading,
          careContextError: careContextError,
          hasSelectedRecipient: selectedElderId != null,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required MedicationProvider medicationProvider,
    required List<MedicineModel> medicines,
    required String? errorMessage,
    required bool isCaregiver,
    required bool hasAssignments,
    required bool isCareContextLoading,
    required String? careContextError,
    required bool hasSelectedRecipient,
  }) {
    if (isCaregiver) {
      if (isCareContextLoading && !hasAssignments) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!hasAssignments) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.users,
          title: 'medication.noPatientsAssigned'.tr(),
          message: 'medication.noPatientsDesc'.tr(),
        );
      }

      if (careContextError != null && !hasSelectedRecipient) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.info,
          title: 'medication.unableToLoadPatients'.tr(),
          message: careContextError,
          onRetry: _loadMedicines,
        );
      }

      if (!hasSelectedRecipient) {
        return _buildCaregiverNotice(
          context,
          icon: FIcons.userSearch,
          title: 'medication.selectPatientContinue'.tr(),
          message: 'medication.selectPatientDesc'.tr(),
        );
      }
    }

    if (medicationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final medicinesForDate = medicationProvider.getMedicinesForDate(
      _selectedDate,
    );

    return Column(
      children: [
        _HeroSummary(
          medicinesCount: medicinesForDate.length,
          isCaregiver: isCaregiver,
          selectedDate: _selectedDate,
        ),
        if (errorMessage != null) ...[
          SizedBox(height: 16.h),
          _ErrorBanner(message: errorMessage, onRetry: _loadMedicines),
        ],
        SizedBox(height: 16.h),
        MedicineCalendarHeader(
          selectedDate: _selectedDate,
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: medicines.isEmpty
              ? _buildEmptyState(context, isCaregiver: isCaregiver)
              : _buildMedicineSchedule(
                  context,
                  medicationProvider,
                  medicinesForDate,
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isCaregiver}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FIcons.pill, size: 48, color: colorScheme.primary),
          SizedBox(height: 12.h),
          Text(
            'medication.noMedicinesAdded'.tr(),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isCaregiver
                ? 'medication.patientNoMedicines'.tr()
                : 'medication.addFirstMedicine'.tr(),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: muted),
          ),
          if (!isCaregiver) ...[
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: AppTheme.appleGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.push('/medicine/add'),
                child: Text(
                  'medication.addMedicine'.tr(),
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineSchedule(
    BuildContext context,
    MedicationProvider medicationProvider,
    List<MedicineModel> medicinesForDate,
  ) {
    final categorized = medicationProvider.categorizeMedicinesByTimeOfDay(
      medicinesForDate,
    );

    if (medicinesForDate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FIcons.calendar,
              size: 64,
              color: context.theme.colors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'medication.noMedicinesForDate'.tr(namedArgs: {'date': _getFormattedDate(_selectedDate)}),
              style: context.theme.typography.lg,
            ),
            const SizedBox(height: 8),
            Text(
              'medication.selectAnotherDate'.tr(),
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (categorized['morning']!.isNotEmpty)
            MedicineScheduleCard(
              key: ValueKey('morning-$_refreshKey'),
              timeOfDay: MedicineTimeOfDay.morning,
              medicines: categorized['morning']!,
              selectedDate: _selectedDate,
              onStatusChanged: () {
                setState(() {
                  _refreshKey++;
                });
              },
            ),
          if (categorized['afternoon']!.isNotEmpty) SizedBox(height: 12.h),
          if (categorized['afternoon']!.isNotEmpty)
            MedicineScheduleCard(
              key: ValueKey('afternoon-$_refreshKey'),
              timeOfDay: MedicineTimeOfDay.afternoon,
              medicines: categorized['afternoon']!,
              selectedDate: _selectedDate,
              onStatusChanged: () {
                setState(() {
                  _refreshKey++;
                });
              },
            ),
          if (categorized['evening']!.isNotEmpty) SizedBox(height: 12.h),
          if (categorized['evening']!.isNotEmpty)
            MedicineScheduleCard(
              key: ValueKey('evening-$_refreshKey'),
              timeOfDay: MedicineTimeOfDay.evening,
              medicines: categorized['evening']!,
              selectedDate: _selectedDate,
              onStatusChanged: () {
                setState(() {
                  _refreshKey++;
                });
              },
            ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final month = _monthLabel(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _monthLabel(int month) {
    final months = [
      'medication.months.jan'.tr(),
      'medication.months.feb'.tr(),
      'medication.months.mar'.tr(),
      'medication.months.apr'.tr(),
      'medication.months.may'.tr(),
      'medication.months.jun'.tr(),
      'medication.months.jul'.tr(),
      'medication.months.aug'.tr(),
      'medication.months.sep'.tr(),
      'medication.months.oct'.tr(),
      'medication.months.nov'.tr(),
      'medication.months.dec'.tr(),
    ];
    return months[month - 1];
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
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'medication.retry'.tr(),
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
    final errorColor = AppTheme.getErrorColor(context);
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context, accent: errorColor),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(FIcons.info, color: errorColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text('medication.retry'.tr()),
          ),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final int medicinesCount;
  final bool isCaregiver;
  final DateTime selectedDate;

  const _HeroSummary({
    required this.medicinesCount,
    required this.isCaregiver,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${selectedDate.day} ${_monthLabel(selectedDate.month)}, ${selectedDate.year}';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    // Compute left-only padding: keep top/bottom/left from heroPadding but
    // reserve the right half for the image.
    final h = ModernSurfaceTheme.heroPadding();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth * 0.4;
          return Container(
            width: double.infinity,
            decoration: ModernSurfaceTheme.heroDecoration(context),
            child: Stack(
              children: [
                // ── Right 50%: image pinned to right edge with padding ─────────────
                Positioned(
                  right: 12.w,
                  top: 12.h,
                  bottom: 12.h,
                  width: halfWidth - 12.w,
                  child: Image.asset(
                    'assets/images/medicine.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ),
                ),
                // ── Left side: text column drives card height ─────────
                Padding(
                  padding: EdgeInsets.only(
                    left: h.left,
                    top: h.top,
                    bottom: h.bottom,
                    right: halfWidth + h.right,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Keep column compact
                    children: [
                      Text(
                        isCaregiver 
                            ? 'medication.hero.careSchedule'.tr() 
                            : 'medication.hero.todaysPlan'.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          color: onPrimary.withValues(alpha: 0.85),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h), // Reduced spacing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: AppTheme.appleGreen,
                            ),
                            child: Text(
                              '$medicinesCount',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded( // Use Expanded inside Row for better wrapping
                            child: Text(
                              'medication.hero.medicinesOnDate'.tr(namedArgs: {'date': dateLabel}),
                                style: textTheme.headlineSmall?.copyWith(
                                color: onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (!isCaregiver) ...[
                        SizedBox(height: 8.h),
                        _HeroChip(
                          icon: Icons.add_circle_outline,
                          label: 'medication.addMedicine'.tr(),
                          onTap: () => context.push('/medicine/add'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _monthLabel(int month) {
    final months = [
      'medication.months.jan'.tr(),
      'medication.months.feb'.tr(),
      'medication.months.mar'.tr(),
      'medication.months.apr'.tr(),
      'medication.months.may'.tr(),
      'medication.months.jun'.tr(),
      'medication.months.jul'.tr(),
      'medication.months.aug'.tr(),
      'medication.months.sep'.tr(),
      'medication.months.oct'.tr(),
      'medication.months.nov'.tr(),
      'medication.months.dec'.tr(),
    ];
    return months[month - 1];
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeroChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.appleGreen,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          SizedBox(width: 8.w),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      );
    }

    return chip;
  }
}
