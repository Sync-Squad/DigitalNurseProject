import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          'settings.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: ModernSurfaceTheme.screenPadding(),
        children: [
          // Notifications section
          Text(
            'settings.notifications.title'.tr(),
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 12.h),

          Container(
            decoration: ModernSurfaceTheme.glassCard(context),
            child: Column(
              children: [
                _ModernSwitchTile(
                  title: 'settings.notifications.medicineReminders.title'.tr(),
                  subtitle:
                      'settings.notifications.medicineReminders.description'
                          .tr(),
                  value: true,
                  onChanged: (_) {},
                ),
                const Divider(height: 1),
                _ModernSwitchTile(
                  title: 'settings.notifications.healthAlerts.title'.tr(),
                  subtitle: 'settings.notifications.healthAlerts.description'
                      .tr(),
                  value: true,
                  onChanged: (_) {},
                ),
                const Divider(height: 1),
                _ModernSwitchTile(
                  title: 'settings.notifications.caregiverUpdates.title'.tr(),
                  subtitle:
                      'settings.notifications.caregiverUpdates.description'
                          .tr(),
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Language section
          Text(
            'settings.language.title'.tr(),
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 12.h),

          Container(
            decoration: ModernSurfaceTheme.glassCard(context),
            child: Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) {
                return Column(
                  children: localeProvider.localeOptions.map((option) {
                    final isSelected = localeProvider.locale == option.locale;
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            FIcons.languages,
                            color: ModernSurfaceTheme.deepTeal.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          title: Text(
                            option.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: ModernSurfaceTheme.deepTeal,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  FIcons.check,
                                  color: ModernSurfaceTheme.primaryTeal,
                                )
                              : null,
                          onTap: () async {
                            // Update EasyLocalization FIRST to ensure .tr() returns correct translations
                            // before widgets rebuild
                            await context.setLocale(option.locale);
                            // Then persist to LocaleProvider (for app restart)
                            await localeProvider.setLocale(option.locale);
                          },
                        ),
                        if (option != localeProvider.localeOptions.last)
                          const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          SizedBox(height: 24.h),

          // Security section
          Text(
            'Security',
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 12.h),

          Container(
            decoration: ModernSurfaceTheme.glassCard(context),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return FutureBuilder<bool>(
                  future: auth.isBiometricLoginAvailable(auth.currentUser?.id ?? ''),
                  builder: (context, snapshot) {
                    final isEnabled = snapshot.data ?? false;
                    return _ModernSwitchTile(
                      title: 'Biometric Login',
                      subtitle: 'Use fingerprint or face recognition to log in',
                      value: isEnabled,
                      onChanged: (value) async {
                        if (value) {
                          // To enable, we need the password. 
                          // Since we don't have it here, we should prompt for it.
                          await _showEnableBiometricDialog(context, auth);
                        } else {
                          await auth.enableBiometric(auth.currentUser?.id ?? '', false);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 24.h),

          // Privacy section
          Text(
            'settings.privacy.title'.tr(),
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 12.h),

          Container(
            decoration: ModernSurfaceTheme.glassCard(context),
            child: Column(
              children: [
                _ModernListTile(
                  icon: FIcons.lock,
                  title: 'settings.privacy.changePassword'.tr(),
                  onTap: () => context.push('/change-password'),
                ),
                const Divider(height: 1),
                _ModernListTile(
                  icon: FIcons.shield,
                  title: 'settings.privacy.privacyPolicy'.tr(),
                  onTap: () => context.push('/privacy-policy'),
                ),
                const Divider(height: 1),
                _ModernListTile(
                  icon: FIcons.fileText,
                  title: 'settings.privacy.termsOfService'.tr(),
                  onTap: () => context.push('/terms-of-service'),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // App section
          Text(
            'settings.about.title'.tr(),
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 12.h),

          Container(
            decoration: ModernSurfaceTheme.glassCard(context),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    FIcons.info,
                    color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    'settings.about.appVersion'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ModernSurfaceTheme.deepTeal,
                    ),
                  ),
                  trailing: Text(
                    '3.1.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _ModernListTile(
                  icon: FIcons.info,
                  title: 'settings.about.helpSupport'.tr(),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _ModernListTile(
                  icon: FIcons.messageCircle,
                  title: 'settings.about.sendFeedback'.tr(),
                  onTap: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Medicine Reminders Diagnostic section
          Text(
            'Medicine Reminders',
            style: ModernSurfaceTheme.sectionTitleStyle(context),
          ),
          SizedBox(height: 12.h),
          _MedicineRemindersDiagnostic(),

          // Debug section (only in debug mode)
          if (const bool.fromEnvironment('dart.vm.product') == false) ...[
            SizedBox(height: 24.h),
            Text(
              'settings.debug.title'.tr(),
              style: ModernSurfaceTheme.sectionTitleStyle(
                context,
              ).copyWith(color: AppTheme.getWarningColor(context)),
            ),
            SizedBox(height: 12.h),
            Container(
              decoration: ModernSurfaceTheme.glassCard(
                context,
                accent: AppTheme.getWarningColor(context),
              ),
              child: ListTile(
                leading: Icon(
                  FIcons.bell,
                  color: AppTheme.getWarningColor(context),
                ),
                title: Text(
                  'settings.debug.testNotifications.title'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ModernSurfaceTheme.deepTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'settings.debug.testNotifications.description'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.65),
                  ),
                ),
                trailing: Icon(
                  FIcons.chevronsRight,
                  color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.4),
                ),
                onTap: () => context.push('/notification-test'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEnableBiometricDialog(BuildContext context, AuthProvider auth) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometric Login'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to enable biometric login for this account.'),
              SizedBox(height: 16.h),
              FTextField(
                controller: passwordController,
                label: const Text('Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password is required')),
                );
                return;
              }

              Navigator.pop(context);
              final success = await auth.enableBiometric(
                auth.currentUser!.id,
                true,
                phone: auth.currentUser!.email, // Using email as identifier
                password: password,
              );
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometric login enabled successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(auth.error ?? 'Failed to enable biometric login')),
                    );
                  }
                }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}

class _ModernSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      activeThumbColor: ModernSurfaceTheme.primaryTeal,
      activeTrackColor: ModernSurfaceTheme.primaryTeal.withValues(alpha: 0.4),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ModernSurfaceTheme.deepTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.65),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ModernListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ModernListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ModernSurfaceTheme.deepTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        FIcons.chevronsRight,
        color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}

class _MedicineRemindersDiagnostic extends StatefulWidget {
  @override
  State<_MedicineRemindersDiagnostic> createState() =>
      _MedicineRemindersDiagnosticState();
}

class _MedicineRemindersDiagnosticState
    extends State<_MedicineRemindersDiagnostic> {
  Map<String, dynamic>? _diagnosticInfo;
  bool _isLoading = false;
  String? _rescheduleMessage;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notificationProvider = context.read<NotificationProvider>();
      final info = await notificationProvider.getDiagnosticInfo();
      setState(() {
        _diagnosticInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rescheduleAllReminders() async {
    setState(() {
      _isLoading = true;
      _rescheduleMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      final user = authProvider.currentUser;

      if (user == null) {
        setState(() {
          _rescheduleMessage = 'Error: User not logged in';
          _isLoading = false;
        });
        return;
      }

      final success = await medicationProvider.rescheduleAllReminders(user.id);
      setState(() {
        _rescheduleMessage = success
            ? 'Reminders rescheduled successfully!'
            : 'Failed to reschedule reminders';
        _isLoading = false;
      });

      // Reload diagnostics
      await _loadDiagnostics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_rescheduleMessage!),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _rescheduleMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        children: [
          if (_isLoading && _diagnosticInfo == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else ...[
            // Status items
            if (_diagnosticInfo != null) ...[
              _DiagnosticItem(
                label: 'FCM Initialized',
                value: _diagnosticInfo!['isInitialized'] == true ? 'Yes' : 'No',
                isGood: _diagnosticInfo!['isInitialized'] == true,
              ),
              const Divider(height: 1),
              _DiagnosticItem(
                label: 'Exact Alarm Permission',
                value: _diagnosticInfo!['exactAlarmPermission'] == true
                    ? 'Granted'
                    : 'Not Granted',
                isGood: _diagnosticInfo!['exactAlarmPermission'] == true,
              ),
              const Divider(height: 1),
            ],
            // Reschedule button
            ListTile(
              leading: Icon(
                FIcons.refreshCw,
                color: ModernSurfaceTheme.primaryTeal,
              ),
              title: Text(
                'Reschedule All Medicine Reminders',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ModernSurfaceTheme.deepTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: _rescheduleMessage != null
                  ? Text(
                      _rescheduleMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _rescheduleMessage!.contains('success')
                            ? Colors.green
                            : Colors.red,
                      ),
                    )
                  : Text(
                      'Reschedule all medicine reminders for the next 7 days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ModernSurfaceTheme.deepTeal.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
              trailing: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      FIcons.chevronsRight,
                      color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.4),
                    ),
              onTap: _isLoading ? null : _rescheduleAllReminders,
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isGood;

  const _DiagnosticItem({
    required this.label,
    required this.value,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ModernSurfaceTheme.deepTeal,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Icon(
                isGood ? FIcons.check : FIcons.x,
                size: 16,
                color: isGood ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isGood
                      ? Colors.green
                      : ModernSurfaceTheme.deepTeal.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
