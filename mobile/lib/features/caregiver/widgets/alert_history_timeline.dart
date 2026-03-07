import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/models/vital_measurement_model.dart';
import '../../../core/extensions/vital_type_extensions.dart';
import '../../../core/theme/modern_surface_theme.dart';
import 'alert_card.dart';

class AlertHistoryTimeline extends StatelessWidget {
  final String elderId;
  final String period; // 'weekly' or 'monthly'

  const AlertHistoryTimeline({
    super.key,
    required this.elderId,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final healthProvider = context.watch<HealthProvider>();

    // Get alerts from notifications
    final notifications = notificationProvider.notifications;
    final alerts = <Map<String, dynamic>>[];

    // Filter by period
    final cutoffDate = period == 'weekly'
        ? DateTime.now().subtract(const Duration(days: 7))
        : DateTime.now().subtract(const Duration(days: 30));

    // Convert notifications to alerts
    for (final notification in notifications) {
      if (notification.timestamp.isAfter(cutoffDate) &&
          (notification.type == NotificationType.healthAlert ||
              notification.type == NotificationType.missedDose)) {
        alerts.add({
          'id': notification.id,
          'type': _mapNotificationTypeToAlertType(notification.type),
          'severity': _getSeverityFromNotification(notification),
          'message': notification.body,
          'timestamp': notification.timestamp,
        });
      }
    }

    // Get abnormal vitals as alerts
    final abnormalVitals = healthProvider.vitals
        .where((v) => v.isAbnormal() && v.timestamp.isAfter(cutoffDate))
        .toList();
    for (final vital in abnormalVitals) {
      alerts.add({
        'id': 'vital_${vital.id}',
        'type': AlertType.abnormalVital,
        'severity': _getSeverityFromVital(vital),
        'message':
            '${vital.type.displayName}: ${vital.value} ${vital.type.unit}',
        'timestamp': vital.timestamp,
      });
    }

    // Sort by timestamp (most recent first)
    alerts.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    // Group by date
    final groupedAlerts = <String, List<Map<String, dynamic>>>{};
    for (final alert in alerts) {
      final date = DateFormat(
        'MMM d, y',
      ).format(alert['timestamp'] as DateTime);
      groupedAlerts.putIfAbsent(date, () => []).add(alert);
    }

    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groupedAlerts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No alerts in this period',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...groupedAlerts.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (alert) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: AlertCard(
                        id: alert['id'] as String,
                        patientName: 'Patient',
                        type: alert['type'] as AlertType,
                        severity: alert['severity'] as AlertSeverity,
                        message: alert['message'] as String,
                        timestamp: alert['timestamp'] as DateTime,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              );
            }),
        ],
      ),
    );
  }

  AlertType _mapNotificationTypeToAlertType(NotificationType type) {
    switch (type) {
      case NotificationType.healthAlert:
        return AlertType.abnormalVital;
      case NotificationType.missedDose:
        return AlertType.missedMedication;
      default:
        return AlertType.general;
    }
  }

  AlertSeverity _getSeverityFromNotification(NotificationModel notification) {
    if (notification.type == NotificationType.healthAlert) {
      return AlertSeverity.high;
    } else if (notification.type == NotificationType.missedDose) {
      return AlertSeverity.medium;
    }
    return AlertSeverity.low;
  }

  AlertSeverity _getSeverityFromVital(VitalMeasurementModel vital) {
    final status = vital.getHealthStatus();
    switch (status) {
      case VitalHealthStatus.emergency:
        return AlertSeverity.critical;
      case VitalHealthStatus.danger:
        return AlertSeverity.critical;
      case VitalHealthStatus.lowBP:
        return AlertSeverity.high;
      case VitalHealthStatus.warning:
        return AlertSeverity.high;
      case VitalHealthStatus.normal:
        return AlertSeverity.low;
    }
  }
}
