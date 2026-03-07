import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/health_provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/models/vital_measurement_model.dart';
import '../../../core/extensions/vital_type_extensions.dart';
import '../../../core/theme/modern_surface_theme.dart';
import 'alert_card.dart';

class EmergencyAlertsSection extends StatelessWidget {
  final String? elderId;
  final String? patientName;

  const EmergencyAlertsSection({super.key, this.elderId, this.patientName});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final healthProvider = context.watch<HealthProvider>();

    // Get alerts from notifications
    final notifications = notificationProvider.notifications;
    final alerts = <Map<String, dynamic>>[];

    // Convert notifications to alerts
    for (final notification in notifications) {
      if (notification.type == NotificationType.healthAlert ||
          notification.type == NotificationType.missedDose) {
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
        .where((v) => v.isAbnormal())
        .toList();
    for (final vital in abnormalVitals.take(5)) {
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

    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency & Alerts',
                style: ModernSurfaceTheme.sectionTitleStyle(context),
              ),
              if (alerts.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          if (alerts.isEmpty)
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
                      'No alerts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...alerts
                .take(5)
                .map(
                  (alert) => AlertCard(
                    id: alert['id'] as String,
                    patientName: patientName ?? 'Patient',
                    type: alert['type'] as AlertType,
                    severity: alert['severity'] as AlertSeverity,
                    message: alert['message'] as String,
                    timestamp: alert['timestamp'] as DateTime,
                    onDismiss: () {
                      // TODO: Dismiss alert
                    },
                  ),
                ),
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
      case NotificationType.medicineReminder:
        return AlertType.missedMedication;
      default:
        return AlertType.general;
    }
  }

  AlertSeverity _getSeverityFromNotification(NotificationModel notification) {
    // Determine severity based on notification type
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
