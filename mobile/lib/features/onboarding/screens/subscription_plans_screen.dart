import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/medication_provider.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/providers/caregiver_provider.dart';
import '../../../core/providers/lifestyle_provider.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/theme/modern_surface_theme.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  SubscriptionTier? _selectedTier;

  Future<void> _handleContinue() async {
    final authProvider = context.read<AuthProvider>();

    // Update subscription if premium selected
    if (_selectedTier == SubscriptionTier.premium) {
      await authProvider.updateSubscription(SubscriptionTier.premium);
    }

    // Load latest data for all providers to sync with backend
    final userId = authProvider.currentUser!.id;
    await Future.wait([
      context.read<MedicationProvider>().loadMedicines(userId),
      context.read<HealthProvider>().loadVitals(userId),
      context.read<CaregiverProvider>().loadCaregivers(userId),
      context.read<LifestyleProvider>().loadAll(userId),
      context.read<DocumentProvider>().loadDocuments(userId),
      context.read<NotificationProvider>().loadNotifications(),
    ]);

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Choose Your Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: ModernSurfaceTheme.screenPadding(),
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
                    'Select a subscription plan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'You can upgrade or downgrade anytime',
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

            // Free plan
            _PlanCard(
              title: 'Free',
              price: 'PKR 0',
              period: 'forever',
              features: const [
                'Basic medicine reminders',
                'Vitals tracking',
                'Up to 2 caregivers',
                'Document storage (50MB)',
                'Email support',
              ],
              isSelected: _selectedTier == SubscriptionTier.free,
              onTap: () {
                setState(() {
                  _selectedTier = SubscriptionTier.free;
                });
              },
            ),
            SizedBox(height: 20.h),

            // Premium plan
            _PlanCard(
              title: 'Premium',
              price: 'PKR 150',
              period: 'per month',
              features: const [
                'Advanced medicine reminders',
                'Unlimited vitals tracking',
                'Unlimited caregivers',
                'Unlimited document storage',
                'Diet & exercise tracking',
                'Health trends & insights',
                'Priority support',
                'Export reports',
              ],
              isSelected: _selectedTier == SubscriptionTier.premium,
              isPremium: true,
              onTap: () {
                setState(() {
                  _selectedTier = SubscriptionTier.premium;
                });
              },
            ),
            SizedBox(height: 32.h),

            // Continue button with modern pill style
            Container(
              decoration: ModernSurfaceTheme.pillButton(
                context,
                ModernSurfaceTheme.primaryTeal,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectedTier != null ? _handleContinue : null,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    alignment: Alignment.center,
                    child: Text(
                      _selectedTier == SubscriptionTier.premium
                          ? 'Upgrade to Premium'
                          : 'Continue with Free',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Skip button (defaults to free)
            TextButton(
              onPressed: () {
                _selectedTier = SubscriptionTier.free;
                _handleContinue();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
              ),
              child: Text(
                'Start with Free Plan',
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
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isSelected;
  final bool isPremium;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isSelected,
    this.isPremium = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isPremium
        ? ModernSurfaceTheme.accentYellow
        : ModernSurfaceTheme.primaryTeal;

    return Container(
      decoration: isSelected
          ? ModernSurfaceTheme.tintedCard(context, accent)
          : ModernSurfaceTheme.glassCard(context, highlighted: isPremium),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: ModernSurfaceTheme.cardRadius(),
          child: Padding(
            padding: ModernSurfaceTheme.cardPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? ModernSurfaceTheme.tintedForegroundColor(
                                        accent,
                                        brightness: Theme.of(
                                          context,
                                        ).brightness,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        if (isPremium) ...[
                          SizedBox(width: 12.w),
                          Container(
                            decoration: ModernSurfaceTheme.frostedChip(context),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            child: Text(
                              'Popular',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        ModernSurfaceTheme.chipForegroundColor(
                                          accent,
                                        ),
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isSelected)
                      Container(
                        decoration: ModernSurfaceTheme.iconBadge(
                          context,
                          accent,
                        ),
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          FIcons.check,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? ModernSurfaceTheme.tintedForegroundColor(
                                    ModernSurfaceTheme.primaryTeal,
                                    brightness: Theme.of(context).brightness,
                                  )
                                : ModernSurfaceTheme.primaryTeal,
                          ),
                    ),
                    SizedBox(width: 6.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        period,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? ModernSurfaceTheme.tintedMutedColor(
                                  accent,
                                  brightness: Theme.of(context).brightness,
                                )
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ...features.map(
                  (feature) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        Container(
                          decoration: ModernSurfaceTheme.iconBadge(
                            context,
                            isSelected
                                ? accent
                                : ModernSurfaceTheme.primaryTeal,
                          ),
                          padding: EdgeInsets.all(4.w),
                          child: Icon(
                            FIcons.check,
                            size: 14.r,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isSelected
                                      ? ModernSurfaceTheme.tintedForegroundColor(
                                          accent,
                                          brightness: Theme.of(
                                            context,
                                          ).brightness,
                                        )
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
