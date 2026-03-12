import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/caregiver_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';

class AddCaregiverScreen extends StatefulWidget {
  const AddCaregiverScreen({super.key});

  @override
  State<AddCaregiverScreen> createState() => _AddCaregiverScreenState();
}

class _AddCaregiverScreenState extends State<AddCaregiverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid email address'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number is required'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final patientId = authProvider.currentUser!.id;

    final invitation = await context.read<CaregiverProvider>().inviteCaregiver(
      patientId: patientId,
      email: email,
      phone: phone,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      relationship: _relationshipController.text.trim().isEmpty
          ? null
          : _relationshipController.text.trim(),
    );

    if (!mounted) return;

    if (invitation != null) {
      _showInvitationSentDialog(invitation);
    } else {
      final error = context.read<CaregiverProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to send invitation'),
          backgroundColor: AppTheme.getErrorColor(context),
        ),
      );
    }
  }

  void _showInvitationSentDialog(Map<String, dynamic> invitation) {
    final inviteCode =
        invitation['inviteCode']?.toString() ?? invitation['code']?.toString();
    final inviteLink = inviteCode != null && inviteCode.isNotEmpty
        ? 'https://digitalnurse.app/invite/$inviteCode'
        : null;
    final expiresAtRaw = invitation['expiresAt'] ?? invitation['expires_at'];
    DateTime? expiresAt;
    if (expiresAtRaw != null) {
      try {
        expiresAt = DateTime.parse(expiresAtRaw.toString());
      } catch (_) {
        expiresAt = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invitation Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An invitation has been sent to the caregiver. Share the link below so they can join and accept.',
            ),
            const SizedBox(height: 16),
            if (inviteLink != null) ...[
              const Text('Shareable Link:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.theme.colors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  inviteLink,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            if (expiresAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Expires: ${expiresAt.toLocal()}',
                style: context.theme.typography.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caregiverProvider = context.watch<CaregiverProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Caregiver',
          style: textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                      Icon(FIcons.userPlus, size: 80.r, color: Colors.white),
                      SizedBox(height: ModernSurfaceTheme.heroSpacing()),

                      // Title
                      Text(
                        'Add Caregiver',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Invite someone to help manage your care',
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
                        label: const Text('Email'),
                        hint: 'caregiver@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20.h),

                      // Phone field
                      FTextField(
                        controller: _phoneController,
                        label: const Text('Phone Number'),
                        hint: '+1234567890',
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 20.h),

                      // Name field (Optional)
                      FTextField(
                        controller: _nameController,
                        label: const Text('Name (Optional)'),
                        hint: 'Caregiver name',
                      ),
                      SizedBox(height: 20.h),

                      // Relationship field (Optional)
                      FTextField(
                        controller: _relationshipController,
                        label: const Text('Relationship (Optional)'),
                        hint: 'e.g., Daughter, Son, Friend',
                      ),
                      SizedBox(height: 28.h),

                      // Send Invitation button with modern pill style
                      Container(
                        decoration: ModernSurfaceTheme.pillButton(
                          context,
                          AppTheme.appleGreen,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: caregiverProvider.isLoading
                                ? null
                                : _handleAdd,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              alignment: Alignment.center,
                              child: caregiverProvider.isLoading
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
                                      'Send Invitation',
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
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
