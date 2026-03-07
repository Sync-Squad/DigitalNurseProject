import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../dashboard_theme.dart';

class CaregiverActionShortcuts extends StatelessWidget {
  const CaregiverActionShortcuts({super.key});

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionShortcut(
        icon: Icons.phone,
        label: 'Call patient',
        caption: 'Connect instantly with a tap.',
        accent: CaregiverDashboardTheme.accentBlue,
        onTap: () => _showComingSoon(context, 'Calling'),
      ),
      _ActionShortcut(
        icon: Icons.notifications_active_outlined,
        label: 'Send reminder',
        caption: 'Nudge caregivers or recipients.',
        accent: CaregiverDashboardTheme.primaryTeal,
        onTap: () => _showComingSoon(context, 'Reminder'),
      ),
      _ActionShortcut(
        icon: Icons.note_alt,
        label: 'View Documents',
        caption: 'Document vitals or incidents.',
        accent: CaregiverDashboardTheme.accentYellow,
        onTap: () => context.push('/documents'),
      ),
      _ActionShortcut(
        icon: Icons.calendar_month,
        label: 'View schedule',
        caption: 'See upcoming medicines.',
        accent: CaregiverDashboardTheme.accentCoral,
        onTap: () => context.push('/medications'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final crossAxisSpacing = 14.w;
        final itemWidth = isWide
            ? (constraints.maxWidth - crossAxisSpacing) / 2
            : constraints.maxWidth;

        return Container(
          padding: CaregiverDashboardTheme.cardPadding(),
          decoration: CaregiverDashboardTheme.glassCard(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: CaregiverDashboardTheme.iconBadge(
                      context,
                      CaregiverDashboardTheme.accentBlue,
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: CaregiverDashboardTheme.sectionTitleStyle(
                            context,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Reach out, log observations, or review schedules without leaving the dashboard.',
                          style: CaregiverDashboardTheme.sectionSubtitleStyle(
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Wrap(
                spacing: crossAxisSpacing,
                runSpacing: 14.h,
                children: actions
                    .map((action) => SizedBox(width: itemWidth, child: action))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionShortcut extends StatefulWidget {
  final IconData icon;
  final String label;
  final String caption;
  final Color accent;
  final VoidCallback onTap;

  const _ActionShortcut({
    required this.icon,
    required this.label,
    required this.caption,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_ActionShortcut> createState() => _ActionShortcutState();
}

class _ActionShortcutState extends State<_ActionShortcut> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleHover(bool value) {
    if (!mounted) return;
    setState(() {
      _isHovered = value;
    });
  }

  void _handlePressed(bool value) {
    if (!mounted) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed
        ? 0.98
        : _isHovered
        ? 1.02
        : 1.0;

    final textTheme = context.theme.typography;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: widget.onTap,
            onHighlightChanged: _handlePressed,
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
              decoration: CaregiverDashboardTheme.pillButton(
                context,
                widget.accent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: CaregiverDashboardTheme.iconBadge(
                      context,
                      Colors.white,
                    ),
                    child: Icon(widget.icon, color: widget.accent),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: textTheme.sm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.caption,
                          style: textTheme.xs.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.north_east_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
