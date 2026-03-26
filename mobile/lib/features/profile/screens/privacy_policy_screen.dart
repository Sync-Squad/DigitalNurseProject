import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'settings.privacy.privacyPolicy'.tr(),
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
                'Privacy Policy',
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
                '1. Introduction',
                'Welcome to My Digital Nurse. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about our policy, or our practices with regards to your personal information, please contact us.',
              ),
              _buildSection(
                context,
                '2. Information We Collect',
                'We collect personal information that you provide to us such as name, contact information, passwords and security data, and payment information. We also collect health-related data you input into the app, such as medication schedules, vitals, and lifestyle logs.',
              ),
              _buildSection(
                context,
                '3. How We Use Your Information',
                'We use personal information collected via our App for a variety of business purposes described below. We process your personal information for these purposes in reliance on our legitimate business interests, in order to enter into or perform a contract with you, with your consent, and/or for compliance with our legal obligations.',
              ),
              _buildSection(
                context,
                '4. Sharing Your Information',
                'We only share information with your consent, to comply with laws, to provide you with services, to protect your rights, or to fulfill business obligations. Specifically, if you are a patient, your data is shared with your designated caregivers as per your settings.',
              ),
              _buildSection(
                context,
                '5. Security of Your Information',
                'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable.',
              ),
              _buildSection(
                context,
                '6. Your Privacy Rights',
                'In some regions (like the EEA), you have certain rights under applicable data protection laws. These may include the right (i) to request access and obtain a copy of your personal information, (ii) to request rectification or erasure; (iii) to restrict the processing of your personal information; and (iv) if applicable, to data portability.',
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
