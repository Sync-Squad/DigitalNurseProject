import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../dashboard_theme.dart';

class ExpandablePatientCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String count;
  final Color accentColor;
  final VoidCallback? onViewDetails;
  final Widget? expandedChild;
  final String? routeForViewDetails;

  const ExpandablePatientCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.accentColor,
    this.onViewDetails,
    this.expandedChild,
    this.routeForViewDetails,
  });

  @override
  State<ExpandablePatientCard> createState() => _ExpandablePatientCardState();
}

class _ExpandablePatientCardState extends State<ExpandablePatientCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleViewDetails() {
    if (widget.routeForViewDetails != null) {
      context.push(widget.routeForViewDetails!);
    } else if (widget.onViewDetails != null) {
      widget.onViewDetails!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final chipForeground = CaregiverDashboardTheme.chipForegroundColor(
      widget.accentColor,
    );
    return Container(
      padding: CaregiverDashboardTheme.cardPadding(),
      decoration: CaregiverDashboardTheme.glassCard(context),
      child: Column(
        children: [
          // Header - expandable area and navigation button
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                // Left side - expandable area
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleExpanded,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: CaregiverDashboardTheme.iconBadge(
                                context,
                                widget.accentColor,
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style:
                                        CaregiverDashboardTheme.sectionTitleStyle(
                                          context,
                                        ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    widget.subtitle,
                                    style:
                                        CaregiverDashboardTheme.sectionSubtitleStyle(
                                          context,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Count badge with chevron (expandable)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleExpanded,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: CaregiverDashboardTheme.frostedChip(
                        context,
                        baseColor: widget.accentColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.count,
                            style: context.theme.typography.sm.copyWith(
                              color: chipForeground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: chipForeground,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Navigation button (always visible)
                if (widget.routeForViewDetails != null) ...[
                  SizedBox(width: 8.w),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleViewDetails,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: widget.accentColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Expanded content
          if (widget.expandedChild != null)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 20.h),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: widget.accentColor.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: widget.expandedChild,
                ),
              ),
            ),
          // View all button (shown when expanded and there's content)
          if (_isExpanded &&
              widget.routeForViewDetails != null &&
              widget.expandedChild != null)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _handleViewDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.accentColor,
                    textStyle: context.theme.typography.xs.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text('patient.viewAll'.tr()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
