import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/vital_measurement_model.dart';
import '../theme/app_theme.dart';

extension VitalStatusExtensions on VitalHealthStatus {
  /// Returns the localized status label (generic label for all vitals)
  String getStatusLabel(BuildContext context) {
    switch (this) {
      case VitalHealthStatus.normal:
        return 'vitals.status.normal.label'.tr();
      case VitalHealthStatus.warning:
        return 'vitals.status.warning.label'.tr();
      case VitalHealthStatus.danger:
        return 'vitals.status.danger.label'.tr();
      case VitalHealthStatus.emergency:
        return 'vitals.status.emergency.label'.tr();
      case VitalHealthStatus.lowBP:
        return 'vitals.status.lowBP.label'.tr();
    }
  }

  /// Returns the appropriate color for this status
  Color getStatusColor(BuildContext context) {
    switch (this) {
      case VitalHealthStatus.normal:
        return AppTheme.getSuccessColor(context);
      case VitalHealthStatus.warning:
        return AppTheme.getWarningColor(context);
      case VitalHealthStatus.danger:
        return AppTheme.getErrorColor(context);
      case VitalHealthStatus.emergency:
        // Darker red for emergency (darker than danger)
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return isDark ? const Color(0xFFDC2626) : const Color(0xFFB91C1C);
      case VitalHealthStatus.lowBP:
        // Blue/Purple for low BP
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1);
    }
  }

  /// Returns the appropriate icon for this status
  IconData getStatusIcon() {
    switch (this) {
      case VitalHealthStatus.normal:
        return Icons.check_circle;
      case VitalHealthStatus.warning:
        return Icons.warning_amber_rounded;
      case VitalHealthStatus.danger:
        return Icons.error;
      case VitalHealthStatus.emergency:
        return Icons.local_hospital;
      case VitalHealthStatus.lowBP:
        return Icons.arrow_downward;
    }
  }
}

extension VitalMeasurementStatusExtensions on VitalMeasurementModel {
  /// Returns the localized status message for blood pressure, or generic label for other vitals
  String getStatusMessage(BuildContext context) {
    if (type == VitalType.bloodPressure) {
      final status = getHealthStatus();
      switch (status) {
        case VitalHealthStatus.normal:
          return 'vitals.status.normal.message'.tr();
        case VitalHealthStatus.warning:
          return 'vitals.status.warning.message'.tr();
        case VitalHealthStatus.danger:
          return 'vitals.status.danger.message'.tr();
        case VitalHealthStatus.emergency:
          return 'vitals.status.emergency.message'.tr();
        case VitalHealthStatus.lowBP:
          return 'vitals.status.lowBP.message'.tr();
      }
    } else {
      // For non-BP vitals, return generic label
      return getHealthStatus().getStatusLabel(context);
    }
  }

  /// Returns the status label (for non-BP vitals or when label is needed instead of message)
  String getStatusLabel(BuildContext context) {
    return getHealthStatus().getStatusLabel(context);
  }
}
