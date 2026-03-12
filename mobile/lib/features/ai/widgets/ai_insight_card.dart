import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/modern_surface_theme.dart';

class AIInsightCard extends StatelessWidget {
  final String id;
  final String title;
  final String content;
  final String priority;
  final String? category;
  final double? confidence;
  final List<dynamic>? recommendations;
  final bool isRead;
  final DateTime generatedAt;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onMarkRead;

  const AIInsightCard({
    super.key,
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    this.category,
    this.confidence,
    this.recommendations,
    this.isRead = false,
    required this.generatedAt,
    this.onTap,
    this.onArchive,
    this.onMarkRead,
  });

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF6B6B);
      case 'high':
        return const Color(0xFFFF9F43);
      case 'medium':
        return ModernSurfaceTheme.accentBlue;
      case 'low':
        return ModernSurfaceTheme.primaryTeal;
      default:
        return ModernSurfaceTheme.primaryTeal;
    }
  }

  IconData _getPriorityIcon() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Icons.error_rounded;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_rounded;
      case 'low':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _priorityLabel() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 'ai.priority.critical'.tr();
      case 'high':
        return 'ai.priority.high'.tr();
      case 'medium':
        return 'ai.priority.medium'.tr();
      case 'low':
        return 'ai.priority.low'.tr();
      default:
        return priority.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getPriorityColor();

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: ModernSurfaceTheme.cardRadius(),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: ModernSurfaceTheme.glassCard(
              context,
              accent: accent,
              highlighted: !isRead,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon + title + unread dot
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: ModernSurfaceTheme.iconBadge(context, accent),
                      child: Icon(
                        _getPriorityIcon(),
                        size: 22.w,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: ModernSurfaceTheme.deepTeal,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _priorityLabel(),
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              if (category != null) ...[
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    category!,
                                    style: TextStyle(
                                      color: ModernSurfaceTheme.deepTeal
                                          .withValues(alpha: 0.6),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 10.w,
                        height: 10.w,
                        margin: EdgeInsets.only(top: 4.h, left: 6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ModernSurfaceTheme.primaryTeal,
                          boxShadow: [
                            BoxShadow(
                              color: ModernSurfaceTheme.primaryTeal.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 14.h),

                // Content preview
                Text(
                  content,
                  style: TextStyle(
                    color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.8),
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Recommendations preview
                if (recommendations != null && recommendations!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: ModernSurfaceTheme.primaryTeal.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ModernSurfaceTheme.primaryTeal.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 16.w,
                              color: ModernSurfaceTheme.accentYellow,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'ai.recommendations'.tr(),
                              style: TextStyle(
                                color: ModernSurfaceTheme.deepTeal,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ...recommendations!
                            .take(2)
                            .map(
                              (rec) => Padding(
                                padding: EdgeInsets.only(bottom: 4.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '•  ',
                                      style: TextStyle(
                                        color: ModernSurfaceTheme.primaryTeal,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rec is String ? rec : rec.toString(),
                                        style: TextStyle(
                                          color: ModernSurfaceTheme.deepTeal
                                              .withValues(alpha: 0.75),
                                          fontSize: 12.sp,
                                          height: 1.4,
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
                ],

                SizedBox(height: 12.h),

                // Footer: time + actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14.w,
                          color: ModernSurfaceTheme.deepTeal.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _formatDate(generatedAt),
                          style: TextStyle(
                            color: ModernSurfaceTheme.deepTeal.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!isRead && onMarkRead != null)
                          _ActionChip(
                            label: 'ai.markRead'.tr(),
                            icon: Icons.done_rounded,
                            color: ModernSurfaceTheme.primaryTeal,
                            onTap: onMarkRead!,
                          ),
                        if (onArchive != null) ...[
                          SizedBox(width: 8.w),
                          _ActionChip(
                            label: 'ai.archive'.tr(),
                            icon: Icons.archive_rounded,
                            color: ModernSurfaceTheme.deepTeal.withValues(
                              alpha: 0.6,
                            ),
                            onTap: onArchive!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'ai.time.minutesAgo'.tr(namedArgs: {'count': '${difference.inMinutes}'});
      }
      return 'ai.time.hoursAgo'.tr(namedArgs: {'count': '${difference.inHours}'});
    } else if (difference.inDays == 1) {
      return 'ai.time.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return 'ai.time.daysAgo'.tr(namedArgs: {'count': '${difference.inDays}'});
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.w, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
