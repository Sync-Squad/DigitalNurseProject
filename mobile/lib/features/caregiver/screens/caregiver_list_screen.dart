import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/caregiver_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/caregiver_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class CaregiverListScreen extends StatefulWidget {
  const CaregiverListScreen({super.key});

  @override
  State<CaregiverListScreen> createState() => _CaregiverListScreenState();
}

class _CaregiverListScreenState extends State<CaregiverListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCaregivers();
    });
  }

  Future<void> _loadCaregivers() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser != null && currentUser.role == UserRole.patient) {
      final caregiverProvider = context.read<CaregiverProvider>();
      await caregiverProvider.loadCaregivers(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final caregiverProvider = context.watch<CaregiverProvider>();
    final activeCaregivers = caregiverProvider.activeCaregivers;
    final inactiveCaregivers = caregiverProvider.inactiveCaregivers;
    final isLoading = caregiverProvider.isLoading;
    final error = caregiverProvider.error;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = colorScheme.onPrimary;
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    // Show loading state
    if (isLoading && caregiverProvider.caregivers.isEmpty) {
      return ModernScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: onPrimary,
          title: const Text('My Caregivers'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (error != null && caregiverProvider.caregivers.isEmpty) {
      return ModernScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: onPrimary,
          title: const Text('My Caregivers'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FIcons.info,
                size: 64.r,
                color: AppTheme.getErrorColor(context),
              ),
              SizedBox(height: 16.h),
              Text(
                'Error loading caregivers',
                style: textTheme.titleLarge?.copyWith(color: onSurface),
              ),
              SizedBox(height: 8.h),
              Text(
                error,
                style: textTheme.bodySmall?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _loadCaregivers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: onPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onPrimary,
        title: Text(
          'My Caregivers',
          style: textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FIcons.plus),
            onPressed: () async {
              await context.push('/caregiver/add');
              // Reload caregivers after returning from add screen
              if (mounted && currentUser != null) {
                await _loadCaregivers();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCaregivers,
        child: caregiverProvider.caregivers.isEmpty
            ? _buildEmptyState(context, colorScheme, textTheme, muted)
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: ModernSurfaceTheme.screenPadding(),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final caregiver = activeCaregivers[index];
                          return _buildCaregiverCard(
                            context,
                            caregiver,
                            textTheme,
                            colorScheme,
                            muted,
                            onPrimary,
                          );
                        },
                        childCount: activeCaregivers.length,
                      ),
                    ),
                  ),
                  if (inactiveCaregivers.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
                        child: Text(
                          'Caregiver History',
                          style: textTheme.titleMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: ModernSurfaceTheme.screenPadding(),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final caregiver = inactiveCaregivers[index];
                            return _buildCaregiverCard(
                              context,
                              caregiver,
                              textTheme,
                              colorScheme,
                              muted,
                              onPrimary,
                              isHistorical: true,
                            );
                          },
                          childCount: inactiveCaregivers.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme,
      TextTheme textTheme, Color muted) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FIcons.users,
                size: 64.r,
                color: colorScheme.primary,
              ),
              SizedBox(height: 16.h),
              Text(
                'No caregivers added yet',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add a caregiver to help manage your care',
                style: textTheme.bodySmall?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => context.push('/caregiver/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Add Caregiver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverCard(
    BuildContext context,
    CaregiverModel caregiver,
    TextTheme textTheme,
    ColorScheme colorScheme,
    Color muted,
    Color onPrimary, {
    bool isHistorical = false,
  }) {
    final accent = ModernSurfaceTheme.primaryTeal.withValues(
      alpha: isHistorical ? 0.3 : 1.0,
    );
    final provider = context.read<CaregiverProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: ModernSurfaceTheme.glassCard(
          context,
          accent: accent,
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: ModernSurfaceTheme.iconBadge(
                    context,
                    accent,
                  ),
                  child: Text(
                    caregiver.name[0].toUpperCase(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onPrimary.withValues(
                        alpha: isHistorical ? 0.7 : 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caregiver.name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withValues(
                            alpha: isHistorical ? 0.6 : 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caregiver.phone,
                        style: textTheme.bodySmall?.copyWith(
                          color: muted.withValues(
                            alpha: isHistorical ? 0.5 : 1.0,
                          ),
                        ),
                      ),
                      if (caregiver.relationship != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          caregiver.relationship!,
                          style: textTheme.bodySmall?.copyWith(
                            color: muted.withValues(
                              alpha: isHistorical ? 0.4 : 0.8,
                            ),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: caregiver.isActive,
                  activeColor: ModernSurfaceTheme.primaryTeal,
                  activeTrackColor:
                      ModernSurfaceTheme.primaryTeal.withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.white.withValues(alpha: 0.8),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  onChanged: (value) async {
                    final success = await provider.toggleCaregiverStatus(
                      caregiver.id,
                      value,
                    );
                    if (mounted && !success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to update status')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: caregiver.isActive
                        ? AppTheme.appleGreen.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    caregiver.isActive ? 'Access Active' : 'Access Disabled',
                    style: textTheme.labelSmall?.copyWith(
                      color: caregiver.isActive
                          ? AppTheme.appleGreen
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDeletion(context, caregiver),
                  icon: Icon(
                    FIcons.trash,
                    size: 14.r,
                    color: Colors.redAccent.withValues(alpha: 0.8),
                  ),
                  label: Text(
                    'Delete Forever',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context, CaregiverModel caregiver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanent Deletion'),
        content: Text(
            'Are you sure you want to permanently delete ${caregiver.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<CaregiverProvider>();
              final success = await provider.removeCaregiver(caregiver.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${caregiver.name} deleted')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
