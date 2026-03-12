import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/caregiver_provider.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../dashboard/widgets/dashboard_theme.dart';
import '../../../core/theme/app_theme.dart';

class ContactCaregiverScreen extends StatefulWidget {
  final String assignmentId;
  final String? caregiverName;

  const ContactCaregiverScreen({
    super.key,
    required this.assignmentId,
    this.caregiverName,
  });

  @override
  State<ContactCaregiverScreen> createState() => _ContactCaregiverScreenState();
}

class _ContactCaregiverScreenState extends State<ContactCaregiverScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('caregiver.messageEmpty'.tr())),
      );
      return;
    }

    final provider = context.read<CaregiverProvider>();
    final success = await provider.contactCaregiver(
      assignmentId: widget.assignmentId,
      message: _messageController.text.trim(),
      subject: _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('caregiver.messageSentSuccess'.tr()),
            backgroundColor: AppTheme.getSuccessColor(context),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'caregiver.messageSentError'.tr()),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: Text(
          'caregiver.contactTitle'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CaregiverDashboardTheme.deepTeal,
                fontWeight: FontWeight.w800,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CaregiverDashboardTheme.deepTeal),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: 40.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 24.h),
            _buildMessageForm(),
            SizedBox(height: 32.h),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: CaregiverDashboardTheme.cardPadding(),
      decoration: CaregiverDashboardTheme.glassCard(
        context,
        accent: CaregiverDashboardTheme.accentYellow,
        highlighted: true,
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: CaregiverDashboardTheme.iconBadge(
              context,
              CaregiverDashboardTheme.accentYellow,
            ),
            child: Icon(
              Icons.contact_mail_rounded,
              color: Colors.white,
              size: 26.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'caregiver.contacting'.tr(),
                  style: CaregiverDashboardTheme.sectionSubtitleStyle(context).copyWith(
                    color: CaregiverDashboardTheme.deepTeal.withValues(alpha: 0.9),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.caregiverName ?? 'caregiver.myCaregiver'.tr(),
                  style: CaregiverDashboardTheme.sectionTitleStyle(context).copyWith(
                    color: CaregiverDashboardTheme.deepTeal,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      padding: CaregiverDashboardTheme.cardPadding(),
      decoration: CaregiverDashboardTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'caregiver.messageFormTitle'.tr(),
            style: CaregiverDashboardTheme.sectionTitleStyle(context).copyWith(
              color: CaregiverDashboardTheme.deepTeal,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _subjectController,
            label: 'caregiver.subjectLabel'.tr(),
            hint: 'caregiver.subjectHint'.tr(),
            icon: Icons.subject,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: _messageController,
            label: 'caregiver.messageLabel'.tr(),
            hint: 'caregiver.messageHint'.tr(),
            icon: Icons.message,
            maxLines: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            label,
            style: CaregiverDashboardTheme.sectionSubtitleStyle(context).copyWith(
              color: CaregiverDashboardTheme.deepTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: CaregiverDashboardTheme.deepTeal, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: CaregiverDashboardTheme.deepTeal.withValues(alpha: 0.5), fontSize: 14.sp),
            prefixIcon: Icon(icon, color: CaregiverDashboardTheme.primaryTeal, size: 22.w),
            filled: true,
            fillColor: CaregiverDashboardTheme.deepTeal.withValues(alpha: 0.05),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: maxLines > 1 ? 16.h : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: CaregiverDashboardTheme.primaryTeal.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Consumer<CaregiverProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          decoration: CaregiverDashboardTheme.pillButton(
            context,
            CaregiverDashboardTheme.primaryTeal,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: provider.isLoading ? null : _sendMessage,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18.h),
                alignment: Alignment.center,
                child: provider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'caregiver.sendMessage'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
