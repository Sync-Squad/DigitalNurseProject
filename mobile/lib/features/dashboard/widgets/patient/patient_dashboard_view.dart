import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/providers/medication_provider.dart';
import '../dashboard_theme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_surface_theme.dart';

import 'due_reminders_row.dart';
import 'patient_action_shortcuts.dart';
import 'patient_documents_card.dart';
import 'patient_lifestyle_card.dart';
import 'patient_upcoming_medications_card.dart';
import 'patient_vitals_card.dart';
import '../../../../core/models/vital_measurement_model.dart';
import '../../../../core/extensions/vital_status_extensions.dart';
import '../../../../features/ai/widgets/ai_insights_dashboard_widget.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final cardSpacing = 16.h;
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/cardbackground1.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
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
              const _HealthOverviewCard(),
              SizedBox(height: cardSpacing),
              const DueRemindersRow(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageWidth = constraints.maxWidth * 0.4;
          return Container(
            decoration: ModernSurfaceTheme.heroDecoration(context),
            child: Stack(
              children: [
                // Right side: Doctor illustration
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: imageWidth * 1.5,
                  child: Image.asset(
                    'assets/images/Avatar10.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
                // Left side: Content
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    20.w,
                    imageWidth + 12.w,
                    20.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text('👋', style: TextStyle(fontSize: 24.sp)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'patient.welcomeBackOnly'.tr(),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: onPrimary.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      userName,
                                      maxLines: 1,
                                      style: textTheme.titleLarge?.copyWith(
                                        color: onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: Text(
                          'patient.heroHealthSubtitle'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: onPrimary.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const _EmbeddedHealthTip(),
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
}

class _EmbeddedHealthTip extends StatelessWidget {
  const _EmbeddedHealthTip();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(16),
      //   color: Colors.white.withValues(alpha: 0.8),
      // ),
    );
  }
}

/// Health Tip Card - DEPRECATED (Moved inside WelcomeHeroCard)
class _HealthTipCard extends StatelessWidget {
  const _HealthTipCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Health Overview Card with circular progress
class _HealthOverviewCard extends StatelessWidget {
  const _HealthOverviewCard();

  @override
  Widget build(BuildContext context) {
    final medicationProvider = context.watch<MedicationProvider>();
    final adherencePercentage = medicationProvider.adherencePercentage
        .clamp(0, 100)
        .toDouble();
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/medications'),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF1FB9AA).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'patient.healthOverview'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  // Left side - Adherence info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                color: Colors.tealAccent.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '😊',
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Flexible(
                              child: Text(
                                'patient.adherencePercentLabel'.tr(namedArgs: {
                                  'percent': adherencePercentage.toInt().toString()
                                }),
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          adherencePercentage >= 80
                              ? 'patient.adherenceGreat'.tr()
                              : 'patient.adherenceMissed'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'patient.improveTogether'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Right side - Circular progress
                  _CircularProgressWidget(
                    percentage: adherencePercentage,
                    size: 75.w,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adherence Card with illustration placeholder
class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard();

  @override
  Widget build(BuildContext context) {
    //final medicationProvider = context.watch<MedicationProvider>();
    //final adherencePercentage = medicationProvider.adherencePercentage
    //    .clamp(0, 100)
    //    .toDouble();
    //final textTheme = Theme.of(context).textTheme;
    return const SizedBox.shrink();
    // return Container(
    //   clipBehavior: Clip.antiAlias,
    //   decoration: ModernSurfaceTheme.heroDecoration(context),
    //   padding: EdgeInsets.all(20.w),
    //   child: Stack(
    //     children: [
    //       Row(
    //         children: [
    //           // Left side - Content
    //           Expanded(
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Row(
    //                   children: [
    //                     Container(
    //                       width: 40.w,
    //                       height: 40.w,
    //                       decoration: BoxDecoration(
    //                         color: AppTheme.appleGreen,
    //                         borderRadius: BorderRadius.circular(12),
    //                       ),
    //                       child: const Icon(
    //                         Icons.grid_view_rounded,
    //                         color: Colors.white,
    //                         size: 22,
    //                       ),
    //                     ),
    //                     SizedBox(width: 12.w),
    //                     Text(
    //                       'Adherence',
    //                       style: textTheme.titleMedium?.copyWith(
    //                         fontWeight: FontWeight.w700,
    //                         color: Colors.white,
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //                 SizedBox(height: 8.h),
    //                 Text(
    //                   adherencePercentage >= 80
    //                       ? 'You\'re doing great this week!'
    //                       : 'You missed some doses this week.',
    //                   style: textTheme.bodyMedium?.copyWith(
    //                     color: Colors.white.withValues(alpha: 0.8),
    //                   ),
    //                 ),
    //                 SizedBox(height: 16.h),
    //                 _SetReminderButton(),
    //               ],
    //             ),
    //           ),
    //           // Spacer for avatar
    //           SizedBox(width: 100.w),
    //         ],
    //       ),
    //       // Right side - Illustration
    //       Positioned(
    //         right: -10,
    //         bottom: -10,
    //         child: Image.asset(
    //           'images/Avatar11.png',
    //           width: 120.w,
    //           fit: BoxFit.contain,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}

/// Alerts and Vitals Row (side by side)
class _AlertsAndVitalsRow extends StatelessWidget {
  const _AlertsAndVitalsRow();

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final abnormalVitals = healthProvider.vitals
        .where((vital) => vital.isAbnormal())
        .toList();

    // Specifically find the latest blood pressure measurement
    final latestBP = healthProvider.vitals.isEmpty
        ? null
        : healthProvider.vitals.firstWhere(
            (v) => v.type == VitalType.bloodPressure,
            orElse: () => healthProvider
                .vitals
                .first, // Fallback if no BP (though we'll handle null in card)
          );

    // If the firstWhere fallback is used, we only want it if it's actually BP
    final actualLatestBP = latestBP?.type == VitalType.bloodPressure
        ? latestBP
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alerts Card
          Expanded(child: _AlertsCard(alertCount: abnormalVitals.length)),
          SizedBox(width: 12.w),
          // Blood Pressure Card
          Expanded(child: _BloodPressureCard(latestVital: actualLatestBP)),
        ],
      ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: alertCount > 0 ? () => context.push('/health/abnormal') : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFFF5E6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFB84D,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFFB84D),
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            'patient.alertsTitle'.tr(),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      alertCount > 0
                          ? 'patient.vitalsNeedCheck'.tr(namedArgs: {
                              'count': alertCount.toString(),
                            })
                          : 'patient.allVitalsGood'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      alertCount > 0
                          ? 'patient.tapToReviewAbnormal'.tr()
                          : 'patient.keepUpGreatWork'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF999999),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Background Icon
              Positioned(
                right: 8.w,
                bottom: 8.h,
                child: Icon(
                  Icons.health_and_safety,
                  size: 32,
                  color: const Color(0xFFFFB84D).withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blood Pressure Card
class _BloodPressureCard extends StatelessWidget {
  final VitalMeasurementModel? latestVital;

  const _BloodPressureCard({this.latestVital});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final vital = latestVital;
    final hasData = vital != null;
    
    // Safely parse blood pressure values
    String systolicStr = '--';
    String diastolicStr = '--';
    
    if (hasData) {
      final valueStr = vital.value.toString();
      final parts = valueStr.split('/');
      systolicStr = parts[0];
      if (parts.length > 1) {
        diastolicStr = parts[1];
      }
    }

    final status = hasData ? vital.getStatusLabel(context) : 'patient.noRecordsYet'.tr();
    final statusColor = hasData
        ? vital.getHealthStatus().getStatusColor(context)
        : const Color(0xFF999999);
    final statusBadgeColor = hasData
        ? statusColor.withValues(alpha: 0.1)
        : const Color(0xFFF5F5F5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasData ? () => context.push('/health') : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                      color: CaregiverDashboardTheme.accentCoral.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: CaregiverDashboardTheme.accentCoral,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'patient.bloodPressureTitle'.tr(),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$systolicStr / $diastolicStr ',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasData
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                    TextSpan(
                      text: 'patient.mmHg'.tr(),
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
                  gradient: LinearGradient(
                    colors: hasData
                        ? [
                            const Color(0xFF4CAF50),
                            const Color(0xFFFFEB3B),
                            const Color(0xFFFF9800),
                            const Color(0xFFF44336),
                          ]
                        : [const Color(0xFFEEEEEE), const Color(0xFFEEEEEE)],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusBadgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular Progress Widget with Beating Heart
class _CircularProgressWidget extends StatelessWidget {
  final double percentage;
  final double size;

  const _CircularProgressWidget({required this.percentage, required this.size});

  @override
  Widget build(BuildContext context) {
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
              strokeWidth: 6.w,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 6.w,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.appleGreen.withValues(alpha: 0.7),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content - Beating Heart and Percentage
          _BeatingHeart(adherencePercentage: percentage),
        ],
      ),
    );
  }
}

class _BeatingHeart extends StatefulWidget {
  final double adherencePercentage;

  const _BeatingHeart({required this.adherencePercentage});

  @override
  State<_BeatingHeart> createState() => _BeatingHeartState();
}

class _BeatingHeartState extends State<_BeatingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Requirements: Very slow heartbeat pulse every 2 seconds (1s pulse, 1s rest/reverse)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Requirements: Scale 1 -> 1.05 -> 1
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_BeatingHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep fixed 2s cycle as per medical aesthetic requirement
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final adherence = widget.adherencePercentage;
    final progress = (adherence / 100).clamp(0.0, 1.0);

    // Natural Red Gradient Palette (Rich & Deep)
    const Color topLineColor = Color(0xFFFF304F);
    const Color bottomLineColor = Color(0xFFC70039);
    const Color glowColor = Color(0x40FF304F); 

    final emptyColor = Colors.white.withOpacity(0.15);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Atmosphere Glow (Outer shadow on dummy icon)
              Icon(
                Icons.favorite,
                color: Colors.transparent,
                size: 30.w,
                shadows: [
                  Shadow(
                    color: glowColor,
                    offset: Offset.zero,
                    blurRadius: 8,
                  ),
                ],
              ),
              // 2. Background Layer: Empty Heart
              Icon(
                Icons.favorite,
                color: emptyColor,
                size: 30.w,
              ),
              // 3. Main Gradient Heart (Clipped for progress)
              ClipRect(
                clipper: _HeartClipper(progress: progress),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base Gradient
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [topLineColor, bottomLineColor],
                        ).createShader(bounds);
                      },
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 30.w,
                      ),
                    ),
                    // Inner Soft Depth Shadow (Slightly offset dark icon)
                    Opacity(
                      opacity: 0.3,
                      child: Padding(
                        padding: EdgeInsets.only(top: 1.h, left: 1.w),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.black,
                          size: 29.w,
                        ),
                      ),
                    ),
                    // Subtle Top-Left Inner Reflection
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: Container(
                        width: 4.w,
                        height: 2.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.all(Radius.elliptical(4.w, 2.h)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '${widget.adherencePercentage.toInt()}%',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}

class _HeartClipper extends CustomClipper<Rect> {
  final double progress;

  _HeartClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      0,
      size.height * (1.0 - progress),
      size.width,
      size.height,
    );
  }

  @override
  bool shouldReclip(_HeartClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Set Reminder Button
class _SetReminderButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: AppTheme.appleGreen,
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
