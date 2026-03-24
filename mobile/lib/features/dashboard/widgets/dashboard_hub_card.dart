import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'dashboard_theme.dart';

class DashboardHubCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<HubAction> actions;

  const DashboardHubCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CaregiverDashboardTheme.glassCard(context, accent: accentColor),
      padding: CaregiverDashboardTheme.cardPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: CaregiverDashboardTheme.iconBadge(context, accentColor),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: CaregiverDashboardTheme.sectionTitleStyle(context),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: actions.map((action) => _HubButton(action: action, accentColor: accentColor)).toList(),
          ),
        ],
      ),
    );
  }
}

class HubAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const HubAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _HubButton extends StatefulWidget {
  final HubAction action;
  final Color accentColor;

  const _HubButton({required this.action, required this.accentColor});

  @override
  State<_HubButton> createState() => _HubButtonState();
}

class _HubButtonState extends State<_HubButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.action.onTap,
          onHighlightChanged: (v) => setState(() => _isPressed = v),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.action.icon, size: 18, color: widget.accentColor),
                SizedBox(width: 8.w),
                Text(
                  widget.action.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                    fontSize: 12.sp,
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
