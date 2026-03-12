import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (widget.token == null) {
      _showErrorSnackBar('Invalid or missing reset token.');
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar('auth.login.passwordRequired'.tr());
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar('auth.login.passwordsDoNotMatch'.tr());
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      token: widget.token!,
      newPassword: password,
    );

    if (mounted && success) {
      setState(() {
        _isSubmitted = true;
      });
      // Redirect to login after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.go('/login');
      });
    } else if (mounted) {
      _showErrorSnackBar(authProvider.error ?? 'Failed to reset password');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.getErrorColor(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ModernScaffold(
      appBar: AppBar(
        title: Text('auth.login.resetPasswordTitle'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: ModernSurfaceTheme.screenPadding(),
          child: Container(
            decoration: ModernSurfaceTheme.glassCard(context, highlighted: true),
            padding: ModernSurfaceTheme.cardPadding(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isSubmitted) ...[
                    Text(
                      'Reset Password'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Enter your new password below.'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    FTextField(
                      controller: _passwordController,
                      label: Text('New Password'.tr()),
                      hint: 'Enter new password'.tr(),
                      obscureText: true,
                    ),
                    SizedBox(height: 20.h),
                    FTextField(
                      controller: _confirmPasswordController,
                      label: Text('Confirm New Password'.tr()),
                      hint: 'Confirm new password'.tr(),
                      obscureText: true,
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      decoration: ModernSurfaceTheme.pillButton(
                        context,
                        AppTheme.appleGreen,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (authProvider.isLoading || widget.token == null)
                              ? null
                              : _handleResetPassword,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Save Password'.tr(),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.token == null) ...[
                      SizedBox(height: 16.h),
                      const Text(
                        'Missing token. Please use the link from your email.',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else ...[
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppTheme.appleGreen,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Password Reset Successful!'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    const Text(
                      'Redirecting to login...',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
