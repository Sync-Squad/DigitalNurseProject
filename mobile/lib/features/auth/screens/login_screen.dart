import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _obscurePassword = true;
  bool _showTestCredentials = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authProvider = context.read<AuthProvider>();
    // Check if biometric is available for any user
    final isAvailable = await authProvider
        .isBiometricLoginAvailableForAnyUser();
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Manual validation as FTextField might not trigger FormState validation correctly
    if (email.isEmpty) {
      _showErrorSnackBar('auth.login.emailRequired'.tr());
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar('auth.login.passwordRequired'.tr());
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(email, password);

    if (mounted) {
      if (success) {
        final currentUser = authProvider.currentUser;
        if (currentUser != null) {
          // Show biometric enable dialog if biometric is available and not already enabled
          final biometricAvailable = await authProvider
              .isBiometricLoginAvailable(currentUser.id);
          if (!biometricAvailable) {
            // Check if device supports biometric
            final biometricService = BiometricService();
            final deviceSupportsBiometric = await biometricService
                .isAvailable();
            if (deviceSupportsBiometric) {
              // Show prompt to enable biometric login
              await _showBiometricEnableDialog(currentUser.id);
            }
          }
        }
        context.go('/home');
      } else {
        final error = authProvider.error ?? 'Login failed';
        // Check if error is about unverified email
        if (error.toLowerCase().contains('verify your email') ||
            error.toLowerCase().contains('email not verified')) {
          await _showEmailVerificationDialog();
        } else {
          _showErrorSnackBar(error);
        }
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authProvider = context.read<AuthProvider>();

    // Get list of users with biometric enabled
    final userIds = await authProvider.getUsersWithBiometricEnabled();

    if (userIds.isEmpty) {
      _showErrorSnackBar(
        'No biometric login set up. Please login with your email and password first, then you can enable biometric login for faster access.',
      );
      return;
    }

    String? selectedUserId;

    // If multiple users, show selection dialog
    if (userIds.length > 1) {
      selectedUserId = await _showUserSelectionDialog(userIds);
      if (selectedUserId == null) {
        // User cancelled selection
        return;
      }
    } else {
      // Single user, use that userId
      selectedUserId = userIds.first;
    }

    // Proceed with biometric login for selected user
    final success = await authProvider.loginWithBiometrics(selectedUserId);

    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        final errorMessage =
            authProvider.error ??
            'Biometric authentication failed or cancelled';
        String userFriendlyMessage;

        if (errorMessage.contains('No saved credentials')) {
          userFriendlyMessage =
              'No saved credentials found for this account.\n\nPlease login with email and password first, then enable biometric login.';
        } else if (errorMessage.contains('not enabled')) {
          userFriendlyMessage =
              'Biometric login is not enabled for this account.\n\nPlease login with email and password and enable biometric login.';
        } else if (errorMessage.contains('cancelled')) {
          userFriendlyMessage =
              'Biometric authentication was cancelled.\n\nPlease try again.';
        } else if (errorMessage.contains('Invalid saved credentials')) {
          userFriendlyMessage =
              'Saved credentials are invalid.\n\nPlease login with email and password again to update your biometric login.';
        } else {
          userFriendlyMessage = errorMessage;
        }

        _showErrorSnackBar(userFriendlyMessage);
      }
    }
  }

  Future<void> _showEmailVerificationDialog() async {
    // Try to get email from user - we'll need to fetch it or ask user
    // For now, show a dialog with option to resend
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Not Verified'),
        content: const Text(
          'Please verify your email address before logging in. Check your inbox for the verification email, or click "Resend" to send a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Navigate to email verification screen
              // We'll need email, but we can ask user or try to get from backend
              final email = _emailController.text.trim();
              context.go('/email-verification?email=${Uri.encodeComponent(email)}');
            },
            child: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    // Extract user-friendly error message
    String errorMessage = message;

    // Remove common prefixes
    if (errorMessage.contains('Unauthorized:')) {
      errorMessage = errorMessage.split('Unauthorized:').last.trim();
    }
    if (errorMessage.contains('Exception: ')) {
      errorMessage = errorMessage.replaceFirst('Exception: ', '');
    }

    // If message is empty or generic, use a default message
    if (errorMessage.isEmpty || errorMessage == 'Login failed') {
      errorMessage = 'Invalid email address or password. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppTheme.getErrorColor(context),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show dialog to prompt user to enable biometric login
  Future<void> _showBiometricEnableDialog(String userId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enable Biometric Login'),
          content: Text(
            'Would you like to enable biometric login for faster access to your account?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Maybe Later'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = context.read<AuthProvider>();
                final currentUser = authProvider.currentUser;
                if (currentUser != null) {
                  final success = await authProvider.saveCredentialsForBiometric(
                    userId: userId,
                    phone: _emailController.text.trim(), // Using email as identifier
                    password: _passwordController.text,
                    verifyFirst: true, // This will trigger the biometric verification prompt
                  );
                  if (mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric login enabled successfully'),
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: ModernSurfaceTheme.primaryTeal,
              ),
              child: Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog to select which user to login with (for multi-user scenarios)
  Future<String?> _showUserSelectionDialog(List<String> userIds) async {
    final secureStorage = SecureStorageService();

    // Get phone numbers for each user
    final List<Map<String, String>> users = [];
    for (final userId in userIds) {
      final phone = await secureStorage.getSavedPhone(userId);
      if (phone != null) {
        users.add({'userId': userId, 'phone': phone});
      }
    }

    if (users.isEmpty) {
      return null;
    }

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Account'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['phone'] ?? 'Unknown'),
                  subtitle: Text('User ID: ${user['userId']}'),
                  onTap: () => Navigator.of(context).pop(user['userId']),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
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
                SizedBox(height: 40.h),

                // Hero section with logo/title
                Container(
                  decoration: ModernSurfaceTheme.heroDecoration(context),
                  padding: ModernSurfaceTheme.heroPadding(),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      // Logo/Icon
                      Icon(FIcons.heartPulse, size: 80.r, color: Colors.white),
                      SizedBox(height: ModernSurfaceTheme.heroSpacing()),

                      // Title
                      Text(
                        'app.name'.tr(),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'auth.login.welcomeBack'.tr(),
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
                      // Email field
                      FTextField(
                        controller: _emailController,
                        label: Text('auth.login.email'.tr()),
                        hint: 'auth.login.emailHint'.tr(),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20.h),

                      // Password field
                      FTextField(
                        controller: _passwordController,
                        label: Text('auth.login.password'.tr()),
                        hint: 'auth.login.passwordHint'.tr(),
                        obscureText: _obscurePassword,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: Text(
                            'auth.login.forgotPassword'.tr(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.appleGreen,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Login button with modern pill style
                      Container(
                        decoration: ModernSurfaceTheme.pillButton(
                          context,
                          AppTheme.appleGreen,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: authProvider.isLoading ? null : _handleLogin,
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
                                      'auth.login.loginButton'.tr(),
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

                // Biometric authentication button
                if (_biometricAvailable) ...[
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'or',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ModernSurfaceTheme.primaryTeal,
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: authProvider.isLoading
                                  ? null
                                  : _handleBiometricLogin,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                child: Icon(
                                  Icons.fingerprint,
                                  size: 32.r,
                                  color: ModernSurfaceTheme.primaryTeal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Use Biometric Login',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],

                // Test credentials section
                Container(
                  decoration: ModernSurfaceTheme.glassCard(context),
                  padding: ModernSurfaceTheme.cardPadding(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showTestCredentials = !_showTestCredentials;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FIcons.info,
                                  size: 20.r,
                                  color: ModernSurfaceTheme.accentBlue,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Test Credentials',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Icon(
                              _showTestCredentials
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      if (_showTestCredentials) ...[
                        SizedBox(height: 16.h),
                        Divider(),
                        SizedBox(height: 12.h),
                        _buildTestCredential(
                          'Patient User',
                          'patient@example.com',
                          'password123',
                        ),
                        SizedBox(height: 12.h),
                        _buildTestCredential(
                          'Caregiver User',
                          'caregiver@example.com',
                          'password123',
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () {
                            _emailController.text = 'patient@example.com';
                            _passwordController.text = 'password123';
                            setState(() {
                              _showTestCredentials = false;
                            });
                          },
                          child: Text(
                            'Use Patient Credentials',
                            style: TextStyle(
                              color: ModernSurfaceTheme.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () {
                            _emailController.text = 'caregiver@example.com';
                            _passwordController.text = 'password123';
                            setState(() {
                              _showTestCredentials = false;
                            });
                          },
                          child: Text(
                            'Use Caregiver Credentials',
                            style: TextStyle(
                              color: ModernSurfaceTheme.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.login.noAccount'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                      ),
                      child: Text(
                        'auth.login.registerLink'.tr(),
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

  Widget _buildTestCredential(String label, String email, String password) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.h),
          Text('Email: $email', style: Theme.of(context).textTheme.bodySmall),
          Text(
            'Password: $password',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
