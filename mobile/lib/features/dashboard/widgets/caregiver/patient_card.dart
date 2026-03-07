import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/care_recipient_model.dart';
import '../../../../core/widgets/professional_avatar.dart';
import '../dashboard_theme.dart';

class PatientCard extends StatelessWidget {
  final CareRecipientModel patient;
  final VoidCallback? onTap;
  final int? index; // Optional index for color assignment

  const PatientCard({super.key, required this.patient, this.onTap, this.index});

  /// Get a color for the patient card based on index or elderId hash
  Color _getCardColor() {
    // Use a hash of elderId to consistently assign colors
    final hash = patient.elderId.hashCode;
    final colors = [
      CaregiverDashboardTheme.primaryTeal,
      CaregiverDashboardTheme.accentBlue,
      CaregiverDashboardTheme.accentYellow,
      CaregiverDashboardTheme.accentCoral,
      const Color(0xFF9B59B6), // Purple
      const Color(0xFFE67E22), // Orange
      const Color(0xFF3498DB), // Blue
      const Color(0xFF1ABC9C), // Turquoise
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getCardColor();
    final brightness = Theme.of(context).brightness;
    final contentColor = CaregiverDashboardTheme.tintedForegroundColor(
      accentColor,
      brightness: brightness,
    );
    final mutedContent = CaregiverDashboardTheme.tintedMutedColor(
      accentColor,
      brightness: brightness,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CaregiverDashboardTheme.cardRadius(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: CaregiverDashboardTheme.tintedCard(context, accentColor),
          child: Row(
            children: [
              // Professional Avatar
              ProfessionalAvatar(
                name: patient.name,
                userId: patient.elderId,
                avatarUrl: patient.avatarUrl,
                size: 48.w,
                backgroundColor: accentColor,
              ),
              SizedBox(width: 16.w),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Patient ID
                    Text(
                      '#PAT${patient.elderId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedContent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Name
                    Text(
                      patient.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: contentColor,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (patient.relationship != null ||
                        patient.age != null) ...[
                      SizedBox(height: 2.h),
                      // Relationship and Age
                      Row(
                        children: [
                          if (patient.relationship != null) ...[
                            Text(
                              patient.relationship!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: mutedContent,
                                    fontSize: 13.sp,
                                  ),
                            ),
                            if (patient.age != null) ...[
                              Text(
                                ' • ',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: mutedContent,
                                      fontSize: 13.sp,
                                    ),
                              ),
                            ],
                          ],
                          if (patient.age != null)
                            Text(
                              '${patient.age} Yrs.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: mutedContent,
                                    fontSize: 13.sp,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Navigation Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: mutedContent),
            ],
          ),
        ),
      ),
    );
  }
}
