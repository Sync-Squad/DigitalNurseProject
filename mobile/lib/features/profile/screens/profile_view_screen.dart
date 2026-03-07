import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/widgets/professional_avatar.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const ModernScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isCaregiver = user.role == UserRole.caregiver;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: onPrimary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ModernSurfaceTheme.screenPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: ModernSurfaceTheme.heroDecoration(context),
              padding: ModernSurfaceTheme.heroPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfessionalAvatar(
                    name: user.name,
                    userId: user.id.isNotEmpty ? user.id : null,
                    avatarUrl: user.avatarUrl,
                    size: 96,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    user.name,
                    style: textTheme.headlineSmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user.email,
                    style: textTheme.bodySmall?.copyWith(
                      color: onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration:
                        user.subscriptionTier == SubscriptionTier.premium
                        ? ModernSurfaceTheme.frostedChip(context)
                        : BoxDecoration(
                            color: AppTheme.appleGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                    child: Text(
                      user.subscriptionTier == SubscriptionTier.premium
                          ? 'Premium Member'
                          : 'Free Plan',
                      style: TextStyle(
                        color: user.subscriptionTier == SubscriptionTier.premium
                            ? ModernSurfaceTheme.chipForegroundColor(
                                Colors.white,
                              )
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Personal information
            Text(
              'Personal Information',
              style: ModernSurfaceTheme.sectionTitleStyle(context),
            ),
            SizedBox(height: 12),

            Container(
              decoration: ModernSurfaceTheme.glassCard(context),
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  if (user.age == null &&
                      user.phone == null &&
                      user.emergencyContact == null &&
                      user.medicalConditions == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            FIcons.userPen,
                            size: 48,
                            color: onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No personal information added yet',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Edit Profile" to add your details',
                            style: textTheme.bodySmall?.copyWith(color: muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (user.age != null)
                      _ProfileInfoRow(
                        icon: FIcons.calendar,
                        label: 'Age',
                        value: user.age!,
                      ),
                    if (user.phone != null) ...[
                      if (user.age != null)
                        Divider(
                          height: 24,
                          color: onSurface.withValues(alpha: 0.1),
                        ),
                      _ProfileInfoRow(
                        icon: FIcons.phone,
                        label: 'Phone',
                        value: user.phone!,
                      ),
                    ],
                    if (user.emergencyContact != null) ...[
                      if (user.age != null || user.phone != null)
                        Divider(
                          height: 24,
                          color: onSurface.withValues(alpha: 0.1),
                        ),
                      _ProfileInfoRow(
                        icon: FIcons.phone,
                        label: 'Emergency Contact',
                        value: user.emergencyContact!,
                      ),
                    ],
                    if (user.medicalConditions != null) ...[
                      if (user.age != null ||
                          user.phone != null ||
                          user.emergencyContact != null)
                        Divider(
                          height: 24,
                          color: onSurface.withValues(alpha: 0.1),
                        ),
                      _ProfileInfoRow(
                        icon: FIcons.heartPulse,
                        label: 'Medical Conditions',
                        value: user.medicalConditions!,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),

            Text(
              'Quick Actions',
              style: ModernSurfaceTheme.sectionTitleStyle(context),
            ),
            SizedBox(height: 12),

            Container(
              decoration: ModernSurfaceTheme.glassCard(context),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _ModernListTile(
                      icon: FIcons.userPen,
                      title: 'Edit Profile',
                      onTap: () => context.push('/profile-setup'),
                    ),
                    const Divider(height: 1),
                    if (!isCaregiver) ...[
                      _ModernListTile(
                        icon: FIcons.creditCard,
                        title: 'Subscription',
                        subtitle:
                            user.subscriptionTier == SubscriptionTier.premium
                            ? 'Manage your premium subscription'
                            : 'Upgrade to Premium',
                        onTap: () => context.push('/subscription-plans'),
                      ),
                      const Divider(height: 1),
                      _ModernListTile(
                        icon: FIcons.users,
                        title: 'Manage Caregivers',
                        onTap: () => context.push('/caregivers'),
                      ),
                      const Divider(height: 1),
                    ],
                    _ThemeSelectorTile(),
                    const Divider(height: 1),
                    _ModernListTile(
                      icon: FIcons.settings,
                      title: 'Settings',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Logout',
                      style: TextStyle(color: context.theme.colors.foreground),
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: context.theme.colors.foreground),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: context.theme.colors.foreground,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Logout',
                          style: TextStyle(color: context.theme.colors.primary),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    context.go('/welcome');
                  }
                }
              },
              icon: const Icon(FIcons.logOut),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: AppTheme.appleGreen,
                foregroundColor: onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: ModernSurfaceTheme.iconBadge(
            context,
            ModernSurfaceTheme.primaryTeal,
          ),
          child: Icon(icon, size: 16, color: colorScheme.onPrimary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodySmall?.copyWith(color: muted)),
              SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeSelectorTile extends StatelessWidget {
  const _ThemeSelectorTile();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ListTile(
      leading: Icon(
        FIcons.palette,
        color: context.theme.colors.mutedForeground,
      ),
      title: Text(
        'Theme',
        style: context.theme.typography.sm.copyWith(
          color: context.theme.colors.foreground,
        ),
      ),
      subtitle: Text(
        themeProvider.themeModeDisplayName,
        style: context.theme.typography.xs.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      trailing: Icon(
        FIcons.chevronsRight,
        color: context.theme.colors.mutedForeground,
      ),
      onTap: () => _showThemeSelector(context, themeProvider),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themeProvider.themeModeOptions.map((option) {
            return RadioListTile<ThemeMode>(
              title: Text(option.name),
              subtitle: Text(option.description),
              value: option.mode,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ModernListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ModernListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: onSurface.withValues(alpha: 0.7)),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.65),
              ),
            ),
      trailing: Icon(
        FIcons.chevronsRight,
        color: onSurface.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}
