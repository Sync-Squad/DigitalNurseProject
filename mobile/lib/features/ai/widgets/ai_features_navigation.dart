import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/modern_surface_theme.dart';

class AIFeaturesNavigation extends StatelessWidget {
  const AIFeaturesNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _AIFeature(
        icon: Icons.chat_bubble_rounded,
        title: 'ai.nav.chatTitle'.tr(),
        description: 'ai.nav.chatDesc'.tr(),
        route: '/ai/assistant',
        accent: ModernSurfaceTheme.primaryTeal,
      ),
      _AIFeature(
        icon: Icons.analytics_rounded,
        title: 'ai.nav.analysisTitle'.tr(),
        description: 'ai.nav.analysisDesc'.tr(),
        route: '/ai/analysis',
        accent: ModernSurfaceTheme.accentCoral,
      ),
      _AIFeature(
        icon: Icons.search_rounded,
        title: 'ai.nav.searchTitle'.tr(),
        description: 'ai.nav.searchDesc'.tr(),
        route: '/ai/search',
        accent: ModernSurfaceTheme.accentBlue,
      ),
      _AIFeature(
        icon: Icons.description_rounded,
        title: 'ai.nav.docQaTitle'.tr(),
        description: 'ai.nav.docQaDesc'.tr(),
        route: '/ai/document-qa',
        accent: ModernSurfaceTheme.accentYellow,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: ModernSurfaceTheme.iconBadge(
                  context,
                  ModernSurfaceTheme.accentBlue,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18.w,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ai.nav.title'.tr(),
                      style: TextStyle(
                        color: ModernSurfaceTheme.deepTeal,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ai.nav.subtitle'.tr(),
                      style: TextStyle(
                        color: ModernSurfaceTheme.deepTeal.withValues(
                          alpha: 0.55,
                        ),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 100.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: features.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final f = features[index];
                return _FeatureChip(feature: f);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AIFeature {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Color accent;

  const _AIFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.accent,
  });
}

class _FeatureChip extends StatefulWidget {
  final _AIFeature feature;

  const _FeatureChip({required this.feature});

  @override
  State<_FeatureChip> createState() => _FeatureChipState();
}

class _FeatureChipState extends State<_FeatureChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.push(widget.feature.route);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 110.w,
          padding: EdgeInsets.all(12.w),
          decoration: ModernSurfaceTheme.tintedCard(
            context,
            widget.feature.accent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: ModernSurfaceTheme.iconBadge(
                  context,
                  widget.feature.accent,
                ),
                child: Icon(
                  widget.feature.icon,
                  color: Colors.white,
                  size: 18.w,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.feature.title,
                    style: TextStyle(
                      color: ModernSurfaceTheme.deepTeal,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.feature.description,
                    style: TextStyle(
                      color: ModernSurfaceTheme.deepTeal.withValues(
                        alpha: 0.55,
                      ),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
