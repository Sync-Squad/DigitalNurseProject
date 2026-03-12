import '../models/vital_measurement_model.dart';
import '../utils/timezone_util.dart';

/// Maps backend vital response to Flutter VitalMeasurementModel
class VitalMapper {
  /// Convert backend API response to VitalMeasurementModel
  static VitalMeasurementModel fromApiResponse(Map<String, dynamic> json) {
    // Convert type string to enum
    VitalType type = VitalType.bloodPressure;
    if (json['type'] != null || json['kindCode'] != null) {
      final typeStr = (json['type'] ?? json['kindCode'])
          .toString()
          .toLowerCase();
      switch (typeStr) {
        case 'bloodpressure':
        case 'blood_pressure':
          type = VitalType.bloodPressure;
          break;
        case 'bloodsugar':
        case 'blood_sugar':
          type = VitalType.bloodSugar;
          break;
        case 'heartrate':
        case 'heart_rate':
          type = VitalType.heartRate;
          break;
        case 'temperature':
          type = VitalType.temperature;
          break;
        case 'oxygensaturation':
        case 'oxygen_saturation':
          type = VitalType.oxygenSaturation;
          break;
        case 'weight':
          type = VitalType.weight;
          break;
        default:
          type = VitalType.bloodPressure;
      }
    }

    // Convert value from backend format (value1/value2/valueText) to string
    String value = '';
    if (json['value'] != null) {
      value = json['value'].toString();
    } else if (json['value1'] != null || json['value2'] != null) {
      // Blood pressure format
      if (json['value1'] != null && json['value2'] != null) {
        value = '${json['value1']}/${json['value2']}';
      } else if (json['value1'] != null) {
        value = json['value1'].toString();
      } else if (json['value2'] != null) {
        value = json['value2'].toString();
      }
    } else if (json['valueText'] != null) {
      value = json['valueText'].toString();
    }

    // Parse timestamp
    DateTime timestamp = DateTime.now();
    if (json['timestamp'] != null) {
      try {
        timestamp = TimezoneUtil.fromPakistanTimeIso8601(
          json['timestamp'].toString(),
        );
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else if (json['recordedAt'] != null) {
      try {
        timestamp = TimezoneUtil.fromPakistanTimeIso8601(
          json['recordedAt'].toString(),
        );
      } catch (e) {
        timestamp = DateTime.now();
      }
    }

    return VitalMeasurementModel(
      id:
          json['id']?.toString() ??
          json['vitalMeasurementId']?.toString() ??
          '',
      type: type,
      value: value,
      timestamp: timestamp,
      notes: json['notes']?.toString(),
      userId:
          json['userId']?.toString() ?? json['elderUserId']?.toString() ?? '',
    );
  }

  /// Convert VitalMeasurementModel to backend API request format
  static Map<String, dynamic> toApiRequest(
    VitalMeasurementModel vital, {
    String? elderUserId,
  }) {
    // Convert type enum to string
    String type;
    switch (vital.type) {
      case VitalType.bloodPressure:
        type = 'bloodPressure';
        break;
      case VitalType.bloodSugar:
        type = 'bloodSugar';
        break;
      case VitalType.heartRate:
        type = 'heartRate';
        break;
      case VitalType.temperature:
        type = 'temperature';
        break;
      case VitalType.oxygenSaturation:
        type = 'oxygenSaturation';
        break;
      case VitalType.weight:
        type = 'weight';
        break;
    }

    // For blood pressure, parse the value string
    // Ensure value is always sent as a string (not a number)
    Map<String, dynamic> request = {
      'type': type,
      'value': vital.value.toString(), // Ensure it's always a string
      'timestamp': TimezoneUtil.toPakistanTimeIso8601(vital.timestamp),
    };

    if (vital.notes != null) {
      request['notes'] = vital.notes;
    }

    if (elderUserId != null && elderUserId.isNotEmpty) {
      // Ensure elderUserId is always sent as a string
      request['elderUserId'] = elderUserId.toString();
    }

    return request;
  }
}
