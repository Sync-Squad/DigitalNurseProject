import '../models/vital_measurement_model.dart';
import '../mappers/vital_mapper.dart';
import '../utils/timezone_util.dart';
import 'api_service.dart';

class VitalsService {
  final ApiService _apiService = ApiService();

  void _log(String message) {
    print('🔍 [VITALS] $message');
  }

  Future<List<VitalMeasurementModel>> getVitals(
    String userId, {
    String? elderUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _log('📋 Fetching vitals for user: $userId (Range: $startDate to $endDate)');
    try {
      final Map<String, dynamic> queryParameters = {};
      if (elderUserId != null) queryParameters['elderUserId'] = elderUserId;
      if (startDate != null) {
        queryParameters['startDate'] = TimezoneUtil.toPakistanTimeIso8601(startDate);
      }
      if (endDate != null) {
        queryParameters['endDate'] = TimezoneUtil.toPakistanTimeIso8601(endDate);
      }

      final response = await _apiService.get(
        '/vitals',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final vitals =
            data
                .map(
                  (json) => VitalMapper.fromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _log('✅ Fetched ${vitals.length} vital measurements');
        return vitals;
      } else {
        _log('❌ Failed to fetch vitals: ${response.statusMessage}');
        throw Exception('Failed to fetch vitals: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error fetching vitals: $e');
      throw Exception(e.toString());
    }
  }

  // Get vitals by type
  Future<List<VitalMeasurementModel>> getVitalsByType(
    String userId,
    VitalType type, {
    String? elderUserId,
  }) async {
    _log('📋 Fetching vitals by type: $type for user: $userId');
    try {
      // Convert type enum to string for API
      String typeStr;
      switch (type) {
        case VitalType.bloodPressure:
          typeStr = 'bloodPressure';
          break;
        case VitalType.bloodSugar:
          typeStr = 'bloodSugar';
          break;
        case VitalType.heartRate:
          typeStr = 'heartRate';
          break;
        case VitalType.temperature:
          typeStr = 'temperature';
          break;
        case VitalType.oxygenSaturation:
          typeStr = 'oxygenSaturation';
          break;
        case VitalType.weight:
          typeStr = 'weight';
          break;
      }

      final queryParameters = {'type': typeStr};
      if (elderUserId != null) {
        queryParameters['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/vitals',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final vitals =
            data
                .map(
                  (json) => VitalMapper.fromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _log('✅ Fetched ${vitals.length} vital measurements of type $type');
        return vitals;
      } else {
        _log('❌ Failed to fetch vitals by type: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch vitals by type: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching vitals by type: $e');
      throw Exception(e.toString());
    }
  }

  // Add vital measurement
  Future<VitalMeasurementModel> addVital(VitalMeasurementModel vital) async {
    _log('➕ Adding vital measurement: ${vital.type}');
    try {
      final requestData = VitalMapper.toApiRequest(
        vital,
        elderUserId: vital.userId,
      );
      final response = await _apiService.post('/vitals', data: requestData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final addedVital = VitalMapper.fromApiResponse(response.data);
        _log('✅ Vital measurement added successfully');
        return addedVital;
      } else {
        _log('❌ Failed to add vital: ${response.statusMessage}');
        throw Exception('Failed to add vital: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error adding vital: $e');
      throw Exception(e.toString());
    }
  }

  // Update vital
  Future<VitalMeasurementModel> updateVital(VitalMeasurementModel vital) async {
    _log('✏️ Updating vital measurement: ${vital.id}');
    try {
      final requestData = VitalMapper.toApiRequest(
        vital,
        elderUserId: vital.userId,
      );
      final response = await _apiService.patch(
        '/vitals/${vital.id}',
        data: requestData,
        queryParameters: vital.userId.isNotEmpty
            ? {'elderUserId': vital.userId}
            : null,
      );

      if (response.statusCode == 200) {
        final updatedVital = VitalMapper.fromApiResponse(response.data);
        _log('✅ Vital measurement updated successfully');
        return updatedVital;
      } else {
        _log('❌ Failed to update vital: ${response.statusMessage}');
        throw Exception('Failed to update vital: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error updating vital: $e');
      throw Exception(e.toString());
    }
  }

  // Delete vital
  Future<void> deleteVital(String vitalId, {String? elderUserId}) async {
    _log('🗑️ Deleting vital measurement: $vitalId');
    try {
      final response = await _apiService.delete(
        '/vitals/$vitalId',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        _log('✅ Vital measurement deleted successfully');
      } else {
        _log('❌ Failed to delete vital: ${response.statusMessage}');
        throw Exception('Failed to delete vital: ${response.statusMessage}');
      }
    } catch (e) {
      _log('❌ Error deleting vital: $e');
      throw Exception(e.toString());
    }
  }

  // Get recent vitals (last 7 days)
  Future<List<VitalMeasurementModel>> getRecentVitals(
    String userId, {
    String? elderUserId,
  }) async {
    _log('📋 Fetching recent vitals (last 7 days) for user: $userId');
    try {
      final cutoffDate = TimezoneUtil.nowInPakistan().subtract(
        const Duration(days: 7),
      );
      final response = await _apiService.get(
        '/vitals',
        queryParameters: {
          'startDate': TimezoneUtil.toPakistanTimeIso8601(cutoffDate),
          if (elderUserId != null) 'elderUserId': elderUserId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final vitals =
            data
                .map(
                  (json) => VitalMapper.fromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _log('✅ Fetched ${vitals.length} recent vital measurements');
        return vitals;
      } else {
        _log('❌ Failed to fetch recent vitals: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch recent vitals: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching recent vitals: $e');
      throw Exception(e.toString());
    }
  }

  // Calculate average for a vital type over a period
  Future<Map<String, dynamic>> calculateTrends(
    String userId,
    VitalType type, {
    int days = 7,
    String? elderUserId,
  }) async {
    _log('📊 Calculating trends for ${type.toString()} (last $days days)');
    try {
      String typeStr;
      switch (type) {
        case VitalType.bloodPressure:
          typeStr = 'bloodPressure';
          break;
        case VitalType.bloodSugar:
          typeStr = 'bloodSugar';
          break;
        case VitalType.heartRate:
          typeStr = 'heartRate';
          break;
        case VitalType.temperature:
          typeStr = 'temperature';
          break;
        case VitalType.oxygenSaturation:
          typeStr = 'oxygenSaturation';
          break;
        case VitalType.weight:
          typeStr = 'weight';
          break;
      }

      final queryParameters = {'kindCode': typeStr};
      if (elderUserId != null) {
        queryParameters['elderUserId'] = elderUserId;
      }

      final response = await _apiService.get(
        '/vitals/trends',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _log('✅ Trends calculated successfully');

        // Handle empty array response - calculate locally as fallback
        if (data is List && data.isEmpty) {
          _log(
            '⚠️ Empty trends data from API, calculating locally as fallback',
          );
          return await _calculateTrendsLocally(
            userId,
            type,
            days: days,
            elderUserId: elderUserId,
          );
        }

        // Handle Map response
        if (data is Map<String, dynamic>) {
          final count = (data['count'] ?? 0) as int;
          // If API returns empty count, try local calculation as fallback
          if (count == 0) {
            _log('⚠️ API returned count=0, calculating locally as fallback');
            return await _calculateTrendsLocally(
              userId,
              type,
              days: days,
              elderUserId: elderUserId,
            );
          }
          return {
            'average': (data['average'] ?? 0.0).toDouble(),
            'count': count,
            'hasAbnormal': (data['hasAbnormal'] ?? false) as bool,
            'measurements': (data['measurements'] ?? [])
                .map(
                  (json) => VitalMapper.fromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList(),
          };
        }

        // Fallback for unexpected data types - calculate locally
        _log(
          '⚠️ Unexpected data type: ${data.runtimeType}, calculating locally as fallback',
        );
        return await _calculateTrendsLocally(
          userId,
          type,
          days: days,
          elderUserId: elderUserId,
        );
      } else {
        _log('❌ Failed to calculate trends: ${response.statusMessage}');
        throw Exception(
          'Failed to calculate trends: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error calculating trends from API: $e');
      _log('🔄 Falling back to local calculation');
      // Fallback to local calculation if API fails
      try {
        return await _calculateTrendsLocally(
          userId,
          type,
          days: days,
          elderUserId: elderUserId,
        );
      } catch (localError) {
        _log('❌ Error in local calculation: $localError');
        throw Exception('Failed to calculate trends: ${e.toString()}');
      }
    }
  }

  // Calculate trends locally from vitals data
  Future<Map<String, dynamic>> _calculateTrendsLocally(
    String userId,
    VitalType type, {
    int days = 7,
    String? elderUserId,
  }) async {
    _log(
      '📊 Calculating trends locally for ${type.toString()} (last $days days)',
    );
    try {
      // Get all vitals for the user
      final allVitals = await getVitals(userId, elderUserId: elderUserId);

      // Filter by type and date range
      final cutoffDate = TimezoneUtil.nowInPakistan().subtract(
        Duration(days: days),
      );
      final filteredVitals = allVitals.where((vital) {
        return vital.type == type && vital.timestamp.isAfter(cutoffDate);
      }).toList();

      if (filteredVitals.isEmpty) {
        _log('⚠️ No vitals found for local calculation');
        return {
          'average': 0.0,
          'count': 0,
          'hasAbnormal': false,
          'measurements': <VitalMeasurementModel>[],
        };
      }

      // Calculate average (handle blood pressure specially)
      double average = 0.0;
      if (type == VitalType.bloodPressure) {
        // For blood pressure, calculate average of systolic values
        final systolicValues = filteredVitals
            .map((v) {
              final parts = v.value.split('/');
              if (parts.length == 2) {
                return int.tryParse(parts[0]) ?? 0;
              }
              return 0;
            })
            .where((v) => v > 0)
            .toList();
        if (systolicValues.isNotEmpty) {
          average =
              systolicValues.reduce((a, b) => a + b) / systolicValues.length;
        }
      } else {
        // For other vitals, parse numeric value
        final numericValues = filteredVitals
            .map((v) => double.tryParse(v.value) ?? 0.0)
            .where((v) => v > 0)
            .toList();
        if (numericValues.isNotEmpty) {
          average =
              numericValues.reduce((a, b) => a + b) / numericValues.length;
        }
      }

      // Check for abnormal readings
      final hasAbnormal = filteredVitals.any((v) => v.isAbnormal());

      _log(
        '✅ Local trends calculated: count=${filteredVitals.length}, average=$average',
      );
      return {
        'average': average,
        'count': filteredVitals.length,
        'hasAbnormal': hasAbnormal,
        'measurements': filteredVitals,
      };
    } catch (e) {
      _log('❌ Error in local trends calculation: $e');
      return {
        'average': 0.0,
        'count': 0,
        'hasAbnormal': false,
        'measurements': <VitalMeasurementModel>[],
      };
    }
  }

  // Check for abnormal readings
  Future<List<VitalMeasurementModel>> getAbnormalReadings(
    String userId, {
    String? elderUserId,
  }) async {
    _log('⚠️ Fetching abnormal readings for user: $userId');
    try {
      final response = await _apiService.get(
        '/vitals/abnormal',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final vitals =
            data
                .map(
                  (json) => VitalMapper.fromApiResponse(
                    json is Map<String, dynamic>
                        ? json
                        : Map<String, dynamic>.from(json),
                  ),
                )
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _log('✅ Fetched ${vitals.length} abnormal readings');
        return vitals;
      } else {
        _log('❌ Failed to fetch abnormal readings: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch abnormal readings: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching abnormal readings: $e');
      throw Exception(e.toString());
    }
  }

  // Get latest vitals per kind
  Future<Map<String, VitalMeasurementModel>> getLatestVitals(
    String userId, {
    String? elderUserId,
  }) async {
    _log('📋 Fetching latest vitals per kind for user: $userId');
    try {
      final response = await _apiService.get(
        '/vitals/latest',
        queryParameters: elderUserId != null
            ? {'elderUserId': elderUserId}
            : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVitals = <String, VitalMeasurementModel>{};

        if (data is Map) {
          data.forEach((key, value) {
            if (value != null) {
              latestVitals[key] = VitalMapper.fromApiResponse(
                value is Map<String, dynamic>
                    ? value
                    : Map<String, dynamic>.from(value),
              );
            }
          });
        }

        _log('✅ Fetched latest vitals for ${latestVitals.length} types');
        return latestVitals;
      } else {
        _log('❌ Failed to fetch latest vitals: ${response.statusMessage}');
        throw Exception(
          'Failed to fetch latest vitals: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching latest vitals: $e');
      throw Exception(e.toString());
    }
  }
}
