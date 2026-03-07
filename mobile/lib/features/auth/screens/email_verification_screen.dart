import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? token;

  const EmailVerificationScreen({super.key, required this.email, this.token});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerifying = false;
  bool _isResending = false;
  bool _isVerified = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // If token is provided, verify immediately
    if (widget.token != null) {
      _verifyEmail(widget.token!);
    }
  }

  Future<void> _verifyEmail(String token) async {
    setState(() {
      _isVerifying = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyEmail(token);

      if (mounted) {
        if (success) {
          setState(() {
            _isVerified = true;
            _isVerifying = false;
          });
          // Wait a moment then redirect
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            context.go('/home');
          }
        } else {
          setState(() {
            _error = authProvider.error ?? 'Verification failed';
            _isVerifying = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.resendVerificationEmail(widget.email);

      if (mounted) {
        if (success) {
          setState(() {
            _successMessage = 'Verification email sent successfully';
            _error = null;
          });
        } else {
          setState(() {
            _error =
                authProvider.error ?? 'Failed to resend verification email';
            _successMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _successMessage = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _handleContinue(BuildContext context) async {
    if (_isVerified) {
      context.go('/home');
    } else {
      // Check verification status
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success icon
                Icon(
                  _isVerified ? Icons.check_circle : FIcons.mailCheck,
                  size: 100.r,
                  color: _isVerified
                      ? Colors.green
                      : context.theme.colors.primary,
                ),
                SizedBox(height: 32.h),

                // Title
                Text(
                  _isVerified ? 'Email Verified!' : 'Verify Your Email',
                  style: context.theme.typography.xl4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),

                if (_isVerifying) ...[
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text(
                    'Verifying your email...',
                    style: context.theme.typography.base,
                    textAlign: TextAlign.center,
                  ),
                ] else if (_isVerified) ...[
                  Text(
                    'Your email has been verified successfully!',
                    style: context.theme.typography.base,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  FButton(
                    onPress: () => _handleContinue(context),
                    child: const Text('Continue'),
                  ),
                ] else ...[
                  // Message
                  Text(
                    'We\'ve sent a verification link to:',
                    style: context.theme.typography.base,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.email,
                    style: context.theme.typography.base.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.theme.colors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Please check your inbox and click the verification link to continue.',
                    style: context.theme.typography.sm,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),

                  if (_error != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: context.theme.typography.sm.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: context.theme.typography.sm.copyWith(
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Resend button
                  FButton(
                    onPress: _isResending ? null : _resendVerificationEmail,
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend Verification Email'),
                  ),
                  SizedBox(height: 16.h),

                  // Resend information
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getWarningColor(
                        context,
                      ).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          FIcons.mail,
                          color: AppTheme.getWarningColor(context),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Didn\'t get the email yet? It can take a few minutes. Click "Resend Verification Email" above to send it again.',
                            style: context.theme.typography.xs.copyWith(
                              color: AppTheme.getWarningColor(context),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Back to login
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Back to Login',
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
