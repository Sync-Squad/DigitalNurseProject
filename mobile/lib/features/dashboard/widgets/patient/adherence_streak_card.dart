import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'animated_heart_icon.dart';
import '../dashboard_theme.dart';

class AdherenceStreakCard extends StatelessWidget {
  final int streakDays;
  final double adherencePercentage;
  final VoidCallback? onSetupPressed;

  const AdherenceStreakCard({
    super.key,
    required this.streakDays,
    required this.adherencePercentage,
    this.onSetupPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;
    
    final accent = adherencePercentage >= 90
        ? CaregiverDashboardTheme.primaryTeal
        : adherencePercentage >= 75
            ? CaregiverDashboardTheme.accentYellow
            : CaregiverDashboardTheme.accentCoral;

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
      width: double.infinity,
      padding: CaregiverDashboardTheme.cardPadding(),
      decoration: CaregiverDashboardTheme.imageCardWithOverlay(
        context,
        image: const AssetImage('assets/card-1.png'),
        accent: accent,
      ),
      child: Row(
        children: [
          // Left side - Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'dashboard.adherenceStreak'.tr(),
                        style: CaregiverDashboardTheme.sectionTitleStyle(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streakDays',
                      style: context.theme.typography.xl.copyWith(
                        color: onTint,
                        fontWeight: FontWeight.w700,
                        fontSize: 32.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        streakDays == 1
                            ? 'dashboard.day'.tr()
                            : 'dashboard.days'.tr(),
                        style: context.theme.typography.sm.copyWith(
                          color: onTintMuted,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'patient.adherenceRate'.tr(namedArgs: {'percent': '${adherencePercentage.toInt()}'}),
                  style: CaregiverDashboardTheme.sectionSubtitleStyle(context)
                      .copyWith(color: onTintMuted),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          // Right side - Heart icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: CaregiverDashboardTheme.iconBadge(context, accent),
                child: Center(
                  child: AnimatedHeartIcon(
                    percentage: adherencePercentage,
                    size: 60.0,
                    fillColor: Colors.red,
                    strokeColor: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: accent.withOpacity(0.25),
                  border: Border.all(
                    color: accent.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  '${adherencePercentage.toInt()}%',
                  style: context.theme.typography.sm.copyWith(
                    color: onTint,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

