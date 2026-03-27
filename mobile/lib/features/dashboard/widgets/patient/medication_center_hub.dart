import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../dashboard_theme.dart';
import 'package:digital_nurse/features/dashboard/widgets/dashboard_hub_card.dart';
import '../../../../core/providers/medication_provider.dart';
import '../../../../core/theme/app_theme.dart';

class MedicationCenterHub extends StatelessWidget {
  const MedicationCenterHub({super.key});

  @override
  Widget build(BuildContext context) {
    // We use context.watch to show the count, same as HeroSummary in medication list
    final medicationProvider = context.watch<MedicationProvider>();
    final medicinesCount = medicationProvider.medicines.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Hero-style Card for Medication Center
        _MedicationHeroHeader(medicinesCount: medicinesCount),
        SizedBox(height: 12.h),
        // Hub Actions
        DashboardHubCard(
          title: 'medication.title'.tr(),
          icon: Icons.medication_rounded,
          accentColor: CaregiverDashboardTheme.primaryTeal,
          actions: [
            HubAction(
              label: 'Create Medication',
              icon: Icons.add_business_rounded,
              onTap: () => context.push('/medicine/add'),
            ),
            HubAction(
              label: 'Medicine History',
              icon: Icons.history_rounded,
              onTap: () => context.push('/medicine/log'),
            ),
            HubAction(
              label: 'Log Medication',
              icon: Icons.add_circle_outline_rounded,
              onTap: () => context.push('/medications'), // Full list already has logging
            ),
            HubAction(
              label: 'Daily Review',
              icon: Icons.assignment_turned_in_rounded,
              onTap: () => context.push('/medication/review'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MedicationHeroHeader extends StatelessWidget {
  final int medicinesCount;

  const _MedicationHeroHeader({required this.medicinesCount});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      decoration: CaregiverDashboardTheme.heroDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image pinned to right (matching Medications screening style)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 140.w,
            child: Image.asset(
              'assets/images/medicine.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
            ),
          ),
          // Content
          Padding(
            padding: CaregiverDashboardTheme.heroPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'medication.hero.todaysPlan'.tr().toUpperCase(),
                  style: textTheme.titleMedium?.copyWith(
                    color: onPrimary.withValues(alpha: 0.8),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppTheme.appleGreen,
                      ),
                      child: Text(
                        '$medicinesCount',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Medicines Tracks for Today',
                        style: textTheme.headlineSmall?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
