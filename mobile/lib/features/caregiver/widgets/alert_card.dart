import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';

enum AlertSeverity { low, medium, high, critical }

enum AlertType {
  needHelp,
  abnormalVital,
  missedMedication,
  inactivity,
  general,
}

class AlertCard extends StatelessWidget {
  final String id;
  final String patientName;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.id,
    required this.patientName,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(context);
    final typeIcon = _getTypeIcon();
    final typeLabel = _getTypeLabel();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: severityColor.withOpacity(0.5),
      ).copyWith(
        border: Border.all(color: severityColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: ModernSurfaceTheme.iconBadge(
                  context,
                  severityColor,
                ),
                child: Icon(typeIcon, size: 20.r, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: severityColor,
                          ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      patientName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 10.h),
          Text(
            DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(BuildContext context) {
    switch (severity) {
      case AlertSeverity.low:
        return AppTheme.getWarningColor(context);
      case AlertSeverity.medium:
        return AppTheme.getWarningColor(context);
      case AlertSeverity.high:
        return AppTheme.getErrorColor(context);
      case AlertSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case AlertType.needHelp:
        return Icons.sos;
      case AlertType.abnormalVital:
        return Icons.monitor_heart;
      case AlertType.missedMedication:
        return Icons.medication_liquid;
      case AlertType.inactivity:
        return Icons.timer_off;
      case AlertType.general:
        return Icons.notifications;
    }
  }

  String _getTypeLabel() {
    switch (type) {
      case AlertType.needHelp:
        return 'Need Help!';
      case AlertType.abnormalVital:
        return 'Abnormal Vital';
      case AlertType.missedMedication:
        return 'Missed Medication';
      case AlertType.inactivity:
        return 'Inactivity Alert';
      case AlertType.general:
        return 'Alert';
    }
  }
}
