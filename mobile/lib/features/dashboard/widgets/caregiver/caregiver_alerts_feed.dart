import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/notification_model.dart';
import '../../../../core/providers/notification_provider.dart';
import '../dashboard_theme.dart';

class CaregiverAlertsFeed extends StatelessWidget {
  const CaregiverAlertsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications.take(5).toList();
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: CaregiverDashboardTheme.cardPadding(),
      decoration: CaregiverDashboardTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: CaregiverDashboardTheme.iconBadge(
                  context,
                  CaregiverDashboardTheme.accentYellow,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care alerts',
                      style: CaregiverDashboardTheme.sectionTitleStyle(context),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Latest updates about medications, vitals, and tasks.',
                      style: CaregiverDashboardTheme.sectionSubtitleStyle(
                        context,
                      ),
                    ),
                  ],
                ),
              ),
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/notifications'),
                  style: TextButton.styleFrom(
                    foregroundColor: CaregiverDashboardTheme.accentYellow,
                    textStyle: context.theme.typography.xs.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('View all'),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          if (notifications.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: CaregiverDashboardTheme.tintedCard(
                context,
                CaregiverDashboardTheme.primaryTeal,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: CaregiverDashboardTheme.iconBadge(
                      context,
                      CaregiverDashboardTheme.primaryTeal,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'No new alerts.',
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CaregiverDashboardTheme.tintedForegroundColor(
                          CaregiverDashboardTheme.primaryTeal,
                          brightness: brightness,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...notifications.asMap().entries.map((entry) {
              final index = entry.key;
              final notification = entry.value;
              final isLast = index == notifications.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
                child: _AlertRow(
                  notification: notification,
                  onTap: () => context.push('/notifications'),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _AlertRow({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = notification.isRead
        ? CaregiverDashboardTheme.accentBlue
        : CaregiverDashboardTheme.accentCoral;
    final brightness = Theme.of(context).brightness;
    final onTint = CaregiverDashboardTheme.tintedForegroundColor(
      accent,
      brightness: brightness,
    );
    final onTintMuted = CaregiverDashboardTheme.tintedMutedColor(
      accent,
      brightness: brightness,
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: CaregiverDashboardTheme.tintedCard(context, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: CaregiverDashboardTheme.iconBadge(context, accent),
                child: Icon(
                  notification.isRead
                      ? Icons.mark_email_read_rounded
                      : Icons.mark_email_unread_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onTint,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.body,
                      style: context.theme.typography.xs.copyWith(
                        color: onTintMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: context.theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            DateFormat('MMM d, h:mm a').format(notification.timestamp),
            style: context.theme.typography.xs.copyWith(color: onTintMuted),
          ),
        ],
      ),
    );
  }
}
