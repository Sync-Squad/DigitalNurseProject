import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'settings.privacy.termsOfService'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Container(
          decoration: ModernSurfaceTheme.glassCard(context),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: ModernSurfaceTheme.sectionTitleStyle(context).copyWith(
                  fontSize: 20.sp,
                  color: ModernSurfaceTheme.deepTeal,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Last Updated: March 2026',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24.h),
              _buildSection(
                context,
                '1. Acceptable Use',
                'By using My Digital Nurse, you agree to follow these Terms of Service. You are responsible for any activity that occurs through your account and you agree you will not sell, transfer, license or assign your account, followers, username, or any account rights.',
              ),
              _buildSection(
                context,
                '2. User Responsibility',
                'You represent that all information you provide or provided to My Digital Nurse upon registration and at all other times will be true, accurate, current and complete and you agree to update your information as necessary to maintain its truth and accuracy.',
              ),
              _buildSection(
                context,
                '3. Health Disclaimer',
                'My Digital Nurse is a tool to help you manage your health and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
              ),
              _buildSection(
                context,
                '4. Intellectual Property',
                'The Service contains content specifically provided by My Digital Nurse or its partners and such content is protected by copyrights, trademarks, service marks, patents, trade secrets or other proprietary rights and laws.',
              ),
              _buildSection(
                context,
                '5. Termination',
                'We may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.',
              ),
              _buildSection(
                context,
                '6. Limitation of Liability',
                'In no event shall My Digital Nurse, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
              ),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  '© 2026 My Digital Nurse. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: ModernSurfaceTheme.deepTeal,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.5,
              color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
