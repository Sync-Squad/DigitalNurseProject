import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Utility class for handling Pakistan timezone conversions
/// Pakistan uses Asia/Karachi timezone (UTC+5, no DST)
class TimezoneUtil {
  static const String pakistanTimeZone = 'Asia/Karachi';
  static bool _initialized = false;

  /// Initialize timezone data (should be called once at app startup)
  static void initialize() {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  /// Convert a DateTime to Pakistan timezone and return as ISO8601 string with offset
  ///
  /// This function takes a DateTime (which may be in any timezone) and converts it
  /// to Pakistan local time, then formats it as ISO8601 with +05:00 offset.
  ///
  /// Example: If input is 2024-01-15 14:00:00 (device local time),
  /// and device is in UTC, output will be "2024-01-15T19:00:00+05:00"
  /// (14:00 UTC + 5 hours = 19:00 PKT)
  ///
  /// If input is already in Pakistan time conceptually (user selected 2:00 PM),
  /// we treat it as Pakistan local time and format accordingly.
  static String toPakistanTimeIso8601(DateTime dateTime) {
    initialize();

    // Get Pakistan timezone location
    final pakistanLocation = tz.getLocation(pakistanTimeZone);

    // Convert the DateTime to Pakistan timezone
    // If dateTime is already in local time (naive), we need to interpret it as Pakistan time
    // If dateTime is UTC, we convert it to Pakistan time
    tz.TZDateTime pakistanTime;

    if (dateTime.isUtc) {
      // If it's UTC, convert to Pakistan timezone
      // Create TZDateTime from UTC, then convert to Pakistan location
      final utcTime = tz.TZDateTime.from(dateTime, tz.UTC);
      pakistanTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
        pakistanLocation,
        utcTime.millisecondsSinceEpoch,
      );
    } else {
      // If it's local time, interpret it as Pakistan local time
      // Create a TZDateTime in Pakistan timezone with the same components
      pakistanTime = tz.TZDateTime(
        pakistanLocation,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );
    }

    // Format as ISO8601 with timezone offset
    // Format: YYYY-MM-DDTHH:mm:ss+05:00
    final year = pakistanTime.year.toString().padLeft(4, '0');
    final month = pakistanTime.month.toString().padLeft(2, '0');
    final day = pakistanTime.day.toString().padLeft(2, '0');
    final hour = pakistanTime.hour.toString().padLeft(2, '0');
    final minute = pakistanTime.minute.toString().padLeft(2, '0');
    final second = pakistanTime.second.toString().padLeft(2, '0');

    // Get timezone offset (should be +05:00 for Pakistan)
    final offset = pakistanTime.timeZoneOffset;
    final offsetHours = offset.inHours;
    final offsetMinutes = (offset.inMinutes % 60).abs();
    final offsetSign = offsetHours >= 0 ? '+' : '-';
    final offsetString =
        '${offsetSign}${offsetHours.abs().toString().padLeft(2, '0')}:${offsetMinutes.toString().padLeft(2, '0')}';

    return '$year-$month-${day}T$hour:$minute:$second$offsetString';
  }

  /// Parse an ISO8601 string (potentially with timezone) and return as DateTime
  ///
  /// If the string contains timezone information, it's parsed correctly.
  /// If it's a date-only string or doesn't have timezone, it's interpreted as Pakistan time.
  static DateTime fromPakistanTimeIso8601(String iso8601String) {
    initialize();

    try {
      // Try to parse as standard ISO8601 (handles timezone offsets automatically)
      final parsed = DateTime.parse(iso8601String);

      // If the string doesn't have timezone info, interpret as Pakistan time
      final hasTimezoneInfo =
          iso8601String.contains('+') ||
          iso8601String.contains('-', 10) ||
          iso8601String.toUpperCase().endsWith('Z');
      if (!hasTimezoneInfo) {
        // No timezone offset in string, interpret as Pakistan local time
        final pakistanLocation = tz.getLocation(pakistanTimeZone);
        final pakistanTime = tz.TZDateTime(
          pakistanLocation,
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
        // Convert to UTC for DateTime (since DateTime doesn't store timezone)
        return pakistanTime.toUtc();
      }

      // If it has timezone info, DateTime.parse converts to UTC equivalent
      // Ensure isUtc flag is set so toPakistanTime() converts correctly
      return parsed.toUtc();
    } catch (e) {
      // Fallback: try to parse as date-only and interpret as Pakistan time
      try {
        final pakistanLocation = tz.getLocation(pakistanTimeZone);
        final dateOnly = DateTime.parse(iso8601String.split('T')[0]);
        final pakistanTime = tz.TZDateTime(
          pakistanLocation,
          dateOnly.year,
          dateOnly.month,
          dateOnly.day,
          0,
          0,
          0,
        );
        return pakistanTime.toUtc();
      } catch (e2) {
        // Last resort: return current time
        return DateTime.now();
      }
    }
  }

  /// Get current time in Pakistan timezone
  static DateTime nowInPakistan() {
    initialize();
    final pakistanLocation = tz.getLocation(pakistanTimeZone);
    return tz.TZDateTime.now(pakistanLocation);
  }

  /// Convert a DateTime to Pakistan timezone TZDateTime (for date extraction)
  /// Returns TZDateTime so we can extract year/month/day in Pakistan timezone
  static tz.TZDateTime toPakistanTime(DateTime dateTime) {
    initialize();
    final pakistanLocation = tz.getLocation(pakistanTimeZone);

    if (dateTime.isUtc) {
      // Convert from UTC to Pakistan timezone
      final utcTime = tz.TZDateTime.from(dateTime, tz.UTC);
      return tz.TZDateTime.fromMillisecondsSinceEpoch(
        pakistanLocation,
        utcTime.millisecondsSinceEpoch,
      );
    } else {
      // Interpret as Pakistan local time
      return tz.TZDateTime(
        pakistanLocation,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );
    }
  }
}
