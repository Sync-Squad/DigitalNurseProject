import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.patient;

  @override
  void initState() {
    super.initState();
    // Add phone number formatter
    _phoneController.addListener(_formatPhoneInput);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_formatPhoneInput);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _formatPhoneInput() {
    final text = _phoneController.text;
    if (text.isEmpty) return;

    // If text doesn't start with +92, format it
    if (!text.startsWith('+92')) {
      final formatted = _formatPhoneNumber(text);
      if (formatted != text) {
        _phoneController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  /// Format phone number to include +92 prefix if not already present
  String _formatPhoneNumber(String phone) {
    // Remove any whitespace
    String cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');

    // If empty, return empty string
    if (cleaned.isEmpty) {
      return '';
    }

    // If already starts with +92, return as is
    if (cleaned.startsWith('+92')) {
      return cleaned;
    }

    // If starts with 92 (without +), add +
    if (cleaned.startsWith('92')) {
      return '+$cleaned';
    }

    // If starts with 0, replace 0 with +92
    if (cleaned.startsWith('0')) {
      return '+92${cleaned.substring(1)}';
    }

    // Otherwise, add +92 prefix
    return '+92$cleaned';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate email (required)
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog('Email is required');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    // Format phone number if provided (optional)
    String? formattedPhone;
    final phoneInput = _phoneController.text.trim();
    if (phoneInput.isNotEmpty) {
      formattedPhone = _formatPhoneNumber(phoneInput);

      // Update the controller with formatted phone
      if (formattedPhone != phoneInput) {
        _phoneController.text = formattedPhone;
      }

      // Validate phone format if provided
      if (!RegExp(r'^\+92\d{10}$').hasMatch(formattedPhone)) {
        _showErrorDialog('Phone must be in format +92XXXXXXXXXX');
        return;
      }
    }

    final inviteCode = _inviteCodeController.text.trim();
    if (_selectedRole == UserRole.caregiver && inviteCode.isEmpty) {
      _showErrorDialog('auth.register.caregiverInviteRequired'.tr());
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      role: _selectedRole,
      phone: formattedPhone,
      caregiverInviteCode: _selectedRole == UserRole.caregiver
          ? inviteCode
          : null,
    );

    if (mounted) {
      if (success) {
        // Redirect to email verification screen if email was provided
        final email = _emailController.text.trim();
        if (email.isNotEmpty) {
          context.go('/email-verification?email=${Uri.encodeComponent(email)}');
        } else {
          // If no email, go to home (phone-only registration)
          context.go('/home');
        }
      } else {
        _showErrorDialog(authProvider.error ?? 'Registration failed');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('auth.register.failed'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: context.theme.colors.primary,
            ),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ModernScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: ModernSurfaceTheme.screenPadding(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),

                // Hero section with logo/title
                Container(
                  decoration: ModernSurfaceTheme.heroDecoration(context),
                  padding: ModernSurfaceTheme.heroPadding(),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      // Logo/Icon
                      Icon(FIcons.userPlus, size: 80.r, color: Colors.white),
                      SizedBox(height: ModernSurfaceTheme.heroSpacing()),

                      // Title
                      Text(
                        'auth.register.title'.tr(),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'auth.register.subtitle'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white.withOpacity(0.9)),
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
                      // Name field
                      FTextField(
                        controller: _nameController,
                        label: Text('auth.register.fullName'.tr()),
                        hint: 'auth.register.nameHint'.tr(),
                      ),
                      SizedBox(height: 20.h),

                      // Email field (required)
                      FTextField(
                        controller: _emailController,
                        label: Text('auth.register.email'.tr()),
                        hint: 'auth.register.emailHint'.tr(),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20.h),

                      // Phone field (optional)
                      FTextField(
                        controller: _phoneController,
                        label: Text('auth.register.phone'.tr()),
                        hint: 'auth.register.phoneHint'.tr(),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Role selection card
                Container(
                  decoration: ModernSurfaceTheme.glassCard(context),
                  padding: ModernSurfaceTheme.cardPadding(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'auth.register.accountType'.tr(),
                        style: ModernSurfaceTheme.sectionTitleStyle(context),
                      ),
                      SizedBox(height: 16.h),
                      ...UserRole.values.map((role) {
                        final isSelected = role == _selectedRole;
                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: isSelected
                              ? ModernSurfaceTheme.tintedCard(
                                  context,
                                  ModernSurfaceTheme.primaryTeal,
                                )
                              : ModernSurfaceTheme.glassCard(context),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: authProvider.isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedRole = role;
                                      });
                                    },
                              borderRadius: ModernSurfaceTheme.cardRadius(),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  children: [
                                    Radio<UserRole>(
                                      value: role,
                                      groupValue: _selectedRole,
                                      onChanged: authProvider.isLoading
                                          ? null
                                          : (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _selectedRole = value;
                                                });
                                              }
                                            },
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            role == UserRole.patient
                                                ? 'auth.register.rolePatient'
                                                      .tr()
                                                : 'auth.register.roleCaregiver'
                                                      .tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: isSelected
                                                      ? ModernSurfaceTheme.tintedForegroundColor(
                                                          ModernSurfaceTheme
                                                              .primaryTeal,
                                                          brightness: Theme.of(
                                                            context,
                                                          ).brightness,
                                                        )
                                                      : Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            role == UserRole.patient
                                                ? 'auth.register.rolePatientDesc'
                                                      .tr()
                                                : 'auth.register.roleCaregiverDesc'
                                                      .tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: isSelected
                                                      ? ModernSurfaceTheme.tintedMutedColor(
                                                          ModernSurfaceTheme
                                                              .primaryTeal,
                                                          brightness: Theme.of(
                                                            context,
                                                          ).brightness,
                                                        )
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                if (_selectedRole == UserRole.caregiver) ...[
                  Container(
                    decoration: ModernSurfaceTheme.glassCard(context),
                    padding: ModernSurfaceTheme.cardPadding(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: ModernSurfaceTheme.iconBadge(
                                context,
                                ModernSurfaceTheme.accentBlue,
                              ),
                              padding: EdgeInsets.all(8.w),
                              child: Icon(
                                FIcons.info,
                                color: Colors.white,
                                size: 20.r,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'auth.register.caregiverInfoTitle'.tr(),
                                    style: ModernSurfaceTheme.sectionTitleStyle(
                                      context,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    'auth.register.caregiverInfoBody'.tr(),
                                    style:
                                        ModernSurfaceTheme.sectionSubtitleStyle(
                                          context,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        FTextField(
                          controller: _inviteCodeController,
                          label: Text('auth.register.inviteCode'.tr()),
                          hint: 'auth.register.inviteCodeHint'.tr(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                // Password fields card
                Container(
                  decoration: ModernSurfaceTheme.glassCard(
                    context,
                    highlighted: true,
                  ),
                  padding: ModernSurfaceTheme.cardPadding(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Password field
                      FTextField(
                        controller: _passwordController,
                        label: Text('auth.register.password'.tr()),
                        hint: 'auth.register.passwordHint'.tr(),
                        obscureText: _obscurePassword,
                      ),
                      SizedBox(height: 20.h),

                      // Confirm Password field
                      FTextField(
                        controller: _confirmPasswordController,
                        label: Text('auth.register.confirmPassword'.tr()),
                        hint: 'auth.register.confirmPasswordHint'.tr(),
                        obscureText: _obscureConfirmPassword,
                      ),
                      SizedBox(height: 28.h),

                      // Register button with modern pill style
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
                                : _handleRegister,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'auth.register.createAccount'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.register.hasAccount'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                      ),
                      child: Text(
                        'auth.register.loginLink'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ModernSurfaceTheme.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
