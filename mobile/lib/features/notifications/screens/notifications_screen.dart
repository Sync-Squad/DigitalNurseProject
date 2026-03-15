import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/widgets/modern_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<NotificationProvider>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return ModernScaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: ModernSurfaceTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ModernSurfaceTheme.screenPadding(),
          child: notificationProvider.isLoading && notifications.isEmpty
              ? SizedBox(
                  height: 400.h,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              : notifications.isEmpty
                  ? _buildEmptyState(context)
                  : _buildNotificationsList(
                      context,
                      notifications,
                      notificationProvider,
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 500.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: ModernSurfaceTheme.iconBadge(
              context,
              Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(
              FIcons.bellOff,
              size: 64.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'You’re all caught up!',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              'We’ll let you know when there’s something new to review.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<NotificationModel> notifications,
    NotificationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: ModernSurfaceTheme.sectionTitleStyle(context).copyWith(
            color: ModernSurfaceTheme.deepTeal,
            fontSize: 18.sp,
          ),
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final timestamp = DateFormat('MMM d • h:mm a').format(notification.timestamp);
            final isUnread = !notification.isRead;

            return Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => provider.deleteNotification(notification.id),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  borderRadius: ModernSurfaceTheme.cardRadius(),
                ),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: const Icon(FIcons.trash, color: Colors.white),
              ),
              child: Container(
                decoration: ModernSurfaceTheme.glassCard(
                  context,
                  accent: isUnread ? ModernSurfaceTheme.primaryTeal : Colors.white60,
                  highlighted: isUnread,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    onTap: () {
                      final authProvider = context.read<AuthProvider>();
                      final careContext = context.read<CareContextProvider>();
                      final user = authProvider.currentUser;

                      String? elderUserId;
                      if (user?.role == UserRole.caregiver) {
                        elderUserId = careContext.selectedElderId;
                      }

                      if (isUnread) {
                        provider.markAsRead(
                          notification.id,
                          elderUserId: elderUserId,
                        );
                      }
                      _handleNotificationTap(context, notification);
                    },
                    leading: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: ModernSurfaceTheme.iconBadge(
                        context,
                        _resolveIconColor(notification.type),
                      ),
                      child: Icon(
                        _resolveIcon(notification.type),
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: ModernSurfaceTheme.deepTeal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontStyle: FontStyle.italic,
                            color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    trailing: isUnread
                        ? Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: const BoxDecoration(
                              color: ModernSurfaceTheme.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    if (notification.actionData == null) return;

    try {
      final dynamic decodedData = jsonDecode(notification.actionData!);
      final Map<String, dynamic> data = decodedData is Map<String, dynamic> ? decodedData : {};

      if (notification.type == NotificationType.medicineReminder ||
          notification.type == NotificationType.missedDose) {
        final medicineId = data['medicationId'] ?? data['medicineId'];
        final reminderTime = data['reminderTime'];
        final scheduledTimeStr = data['scheduledTime'];

        if (medicineId != null) {
          String route = '/medicine/$medicineId';
          final queryParams = <String, String>{};

          if (reminderTime != null) {
            queryParams['reminderTime'] = reminderTime.toString();
          }

          if (scheduledTimeStr != null) {
            queryParams['selectedDate'] = scheduledTimeStr.toString();
          }

          if (queryParams.isNotEmpty) {
            final uri = Uri(path: route, queryParameters: queryParams);
            context.push(uri.toString());
          } else {
            context.push(route);
          }
        }
      } else if (notification.type == NotificationType.caregiverInvitation) {
        final caregiverId = data['caregiverId'];
        if (caregiverId != null) {
          context.push('/invitation-accept/$caregiverId');
        }
      } else if (notification.type == NotificationType.healthAlert) {
        context.push('/health/abnormal');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  IconData _resolveIcon(NotificationType type) {
    switch (type) {
      case NotificationType.medicineReminder:
      case NotificationType.missedDose:
        return FIcons.pill;
      case NotificationType.healthAlert:
        return FIcons.activity;
      case NotificationType.caregiverInvitation:
        return FIcons.users;
      case NotificationType.general:
      default:
        return FIcons.bell;
    }
  }

  Color _resolveIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.medicineReminder:
        return ModernSurfaceTheme.primaryTeal;
      case NotificationType.missedDose:
      case NotificationType.healthAlert:
        return ModernSurfaceTheme.accentCoral;
      case NotificationType.caregiverInvitation:
        return ModernSurfaceTheme.accentBlue;
      case NotificationType.general:
      default:
        return ModernSurfaceTheme.primaryTeal;
    }
  }
}
