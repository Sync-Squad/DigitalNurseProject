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

import 'package:digital_nurse/features/caregiver/widgets/medication_status_card.dart';
import '../../../../features/ai/widgets/ai_insights_dashboard_widget.dart';

import 'alerts_bp_grid.dart';
import 'dashboard_hub_grid.dart';

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
              const AlertsBPGrid(),
              SizedBox(height: cardSpacing),
              
              const DashboardHubGrid(),
              
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

