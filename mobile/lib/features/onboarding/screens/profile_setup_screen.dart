import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ageController.dispose();
    _phoneController.dispose();
    _medicalConditionsController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      age: _ageController.text.trim(),
      phone: _phoneController.text.trim(),
      medicalConditions: _medicalConditionsController.text.trim(),
      emergencyContact: _emergencyContactController.text.trim(),
    );

    if (mounted) {
      if (success) {
        context.go('/subscription-plans');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to update profile'),
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.white,
        ),
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.h),

              // Hero section
              Container(
                decoration: ModernSurfaceTheme.heroDecoration(context),
                padding: ModernSurfaceTheme.heroPadding(),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      'Help us personalize your experience',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'This information helps us provide better care recommendations',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Form container with glassmorphic card
              Container(
                decoration: ModernSurfaceTheme.glassCard(
                  context,
                  highlighted: true,
                ),
                padding: ModernSurfaceTheme.cardPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Age field
                    FTextField(
                      controller: _ageController,
                      label: const Text('Age'),
                      hint: 'Enter your age',
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20.h),

                    // Phone field
                    FTextField(
                      controller: _phoneController,
                      label: const Text('Phone Number'),
                      hint: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20.h),

                    // Medical conditions field
                    FTextField(
                      controller: _medicalConditionsController,
                      label: const Text('Medical Conditions (Optional)'),
                      hint: 'e.g., Diabetes, Hypertension',
                      maxLines: 3,
                    ),
                    SizedBox(height: 20.h),

                    // Emergency contact field
                    FTextField(
                      controller: _emergencyContactController,
                      label: const Text('Emergency Contact'),
                      hint: 'Name and phone number',
                    ),
                    SizedBox(height: 28.h),

                    // Continue button with modern pill style
                    Container(
                      decoration: ModernSurfaceTheme.pillButton(
                        context,
                        ModernSurfaceTheme.primaryTeal,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: authProvider.isLoading
                              ? null
                              : _handleContinue,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            alignment: Alignment.center,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Skip button
              TextButton(
                onPressed: () => context.go('/subscription-plans'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 24.w,
                  ),
                ),
                child: Text(
                  'Skip for now',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ModernSurfaceTheme.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
