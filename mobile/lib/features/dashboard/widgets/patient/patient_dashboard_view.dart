import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../dashboard_theme.dart';
import 'patient_action_shortcuts.dart';
import 'patient_documents_card.dart';
import 'patient_lifestyle_card.dart';
import 'patient_upcoming_medications_card.dart';
import 'patient_vitals_card.dart';
import '../../../../features/ai/widgets/ai_insights_dashboard_widget.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final cardSpacing = 16.h;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: 40.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WelcomeHeroCard(),
            SizedBox(height: cardSpacing),
            const _HealthTipCard(),
            SizedBox(height: cardSpacing),
            const _HealthOverviewCard(),
            SizedBox(height: cardSpacing),
            const _AdherenceCard(),
            SizedBox(height: cardSpacing),
            const _AlertsAndVitalsRow(),
            SizedBox(height: cardSpacing),
            const PatientActionShortcuts(),
            SizedBox(height: cardSpacing),
            const PatientUpcomingMedicationsCard(),
            SizedBox(height: cardSpacing),
            const PatientVitalsCard(),
            SizedBox(height: cardSpacing),
            const PatientDocumentsCard(),
            SizedBox(height: cardSpacing),
            const PatientLifestyleCard(),
            SizedBox(height: cardSpacing),
            const AIInsightsDashboardWidget(),
          ],
        ),
      ),
    );
  }
}

/// Welcome Hero Card with doctor illustration placeholder
class _WelcomeHeroCard extends StatelessWidget {
  const _WelcomeHeroCard();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final userName = user?.name ?? 'common.user'.tr();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8F5F3),
            const Color(0xFFF0F9F7),
          ],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/Card-2.png'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '👋',
                      style: TextStyle(fontSize: 24.sp),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'patient.welcomeBack'.tr(namedArgs: {'name': ''}),
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userName,
                            style: textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: 200.w,
                  child: Text(
                    'patient.heroDescription'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4A4A4A),
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 60.h), // Space for illustration
              ],
            ),
          ),
          // Placeholder for doctor illustration (right side)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 140.w,
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.person,
                size: 100,
                color: CaregiverDashboardTheme.primaryTeal.withValues(alpha:0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Health Tip Card
class _HealthTipCard extends StatelessWidget {
  const _HealthTipCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: CaregiverDashboardTheme.primaryTeal.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: CaregiverDashboardTheme.primaryTeal,
              size: 20,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Tip Today',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Drink water before taking your medicine.',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF666666),
                  ),
                ),
                Text(
                  'Even small steps matter.',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF999999),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Placeholder for medicine/water illustration
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_drink,
              color: CaregiverDashboardTheme.primaryTeal,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

/// Health Overview Card with circular progress
class _HealthOverviewCard extends StatelessWidget {
  const _HealthOverviewCard();

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final adherencePercentage =
        medicationProvider.adherencePercentage.clamp(0, 100).toDouble();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Overview',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              // Left side - Adherence info
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFFF9E6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '😊',
                                style: TextStyle(fontSize: 20.sp),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            '${adherencePercentage.toInt()}% Adherence',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        adherencePercentage >= 80
                            ? 'Great job this week!'
                            : 'You missed some doses this week.',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _SetReminderButton(),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Right side - Circular progress
              _CircularProgressWidget(
                percentage: adherencePercentage,
                size: 100.w,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Adherence Card with illustration placeholder
class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard();

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final adherencePercentage =
        medicationProvider.adherencePercentage.clamp(0, 100).toDouble();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/card-1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha:0.95),
              Colors.white.withValues(alpha:0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            // Left side - Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: CaregiverDashboardTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Adherence',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    adherencePercentage >= 80
                        ? 'You\'re doing great this week!'
                        : 'You missed some doses this week.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _SetReminderButton(),
                ],
              ),
            ),
            // Right side - Illustration placeholder
            SizedBox(
              width: 100.w,
              child: Icon(
                Icons.medical_services,
                size: 80,
                color: CaregiverDashboardTheme.primaryTeal.withValues(alpha:0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alerts and Vitals Row (side by side)
class _AlertsAndVitalsRow extends StatelessWidget {
  const _AlertsAndVitalsRow();

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final abnormalVitals =
        healthProvider.vitals.where((vital) => vital.isAbnormal()).toList();
    final latestVital =
        healthProvider.vitals.isNotEmpty ? healthProvider.vitals.first : null;

    return Row(
      children: [
        // Alerts Card
        Expanded(
          child: _AlertsCard(alertCount: abnormalVitals.length),
        ),
        SizedBox(width: 12.w),
        // Blood Pressure Card
        Expanded(
          child: _BloodPressureCard(latestVital: latestVital),
        ),
      ],
    );
  }
}

/// Alerts Card
class _AlertsCard extends StatelessWidget {
  final int alertCount;

  const _AlertsCard({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFF5E6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB84D).withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFB84D),
                  size: 18,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Alerts',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            alertCount > 0
                ? '$alertCount vitals need a quick check'
                : 'All vitals look good!',
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            alertCount > 0
                ? 'Tap to review your abnormal vitals safely.'
                : 'Keep up the great work!',
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF999999),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 12.h),
          // Illustration placeholder
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.health_and_safety,
              size: 40,
              color: const Color(0xFFFFB84D).withValues(alpha:0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blood Pressure Card
class _BloodPressureCard extends StatelessWidget {
  final dynamic latestVital;

  const _BloodPressureCard({this.latestVital});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Default values if no vital data
    final systolic = 130;
    final diastolic = 95;
    final status = 'High (Stage 1)';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: CaregiverDashboardTheme.accentCoral.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite,
                  color: CaregiverDashboardTheme.accentCoral,
                  size: 18,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Blood Pressure',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$systolic / $diastolic ',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                TextSpan(
                  text: 'mmHg',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // Gradient indicator
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFFFFEB3B),
                  Color(0xFFFF9800),
                  Color(0xFFF44336),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular Progress Widget
class _CircularProgressWidget extends StatelessWidget {
  final double percentage;
  final double size;

  const _CircularProgressWidget({
    required this.percentage,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                CaregiverDashboardTheme.primaryTeal,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.toInt()}%',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'adherence—',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF666666),
                  fontSize: 10.sp,
                ),
              ),
              Text(
                'let\'s improve',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF666666),
                  fontSize: 10.sp,
                ),
              ),
              Text(
                'together',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF666666),
                  fontSize: 10.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Icon(
                Icons.favorite,
                color: CaregiverDashboardTheme.primaryTeal,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Set Reminder Button
class _SetReminderButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: CaregiverDashboardTheme.primaryTeal,
      ),
      child: Text(
        'Set Reminder',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
