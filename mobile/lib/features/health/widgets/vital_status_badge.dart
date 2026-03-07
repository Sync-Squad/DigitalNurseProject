import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/vital_measurement_model.dart';
import '../../../core/extensions/vital_status_extensions.dart';

class VitalStatusBadge extends StatelessWidget {
  final VitalHealthStatus status;
  final VitalMeasurementModel? vital;

  const VitalStatusBadge({super.key, required this.status, this.vital});

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes
    // ignore: unused_local_variable
    final _ = context.locale;

    final statusColor = status.getStatusColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        _getStatusText(context),
        style: context.theme.typography.xs.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getStatusText(BuildContext context) {
    // If vital is provided and it's blood pressure, use BP-specific message
    if (vital != null && vital!.type == VitalType.bloodPressure) {
      return vital!.getStatusMessage(context);
    }
    // Otherwise use generic label
    return status.getStatusLabel(context);
  }
}
