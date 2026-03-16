import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
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
    final pakistanLocation = tz.getLocation(pakistanTimeZone);

    // Always normalize to the absolute point in time and view it in Pakistan location
    final pktTime = tz.TZDateTime.from(dateTime.toUtc(), pakistanLocation);

    // Format as ISO8601 with +05:00 offset
    final year = pktTime.year.toString().padLeft(4, '0');
    final month = pktTime.month.toString().padLeft(2, '0');
    final day = pktTime.day.toString().padLeft(2, '0');
    final hour = pktTime.hour.toString().padLeft(2, '0');
    final minute = pktTime.minute.toString().padLeft(2, '0');
    final second = pktTime.second.toString().padLeft(2, '0');

    return '$year-$month-${day}T$hour:$minute:${second}+05:00';
  }

  /// Helper to format a DateTime for display in Pakistan time (h:mm a or similar)
  static String formatInPakistan(DateTime dateTime, {String format = 'MMM dd, yyyy h:mm a'}) {
    initialize();
    final pktTime = toPakistanTime(dateTime);
    return DateFormat(format).format(pktTime);
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
        return DateTime.now().toUtc();
      }
    }
  }

  /// Get current time in Pakistan timezone
  static tz.TZDateTime nowInPakistan() {
    initialize();
    final pakistanLocation = tz.getLocation(pakistanTimeZone);
    return tz.TZDateTime.now(pakistanLocation);
  }

  /// Convert a DateTime to Pakistan timezone TZDateTime
  static tz.TZDateTime toPakistanTime(DateTime dateTime) {
    initialize();
    final pakistanLocation = tz.getLocation(pakistanTimeZone);
    // Always use .from() with UTC to ensure absolute point-in-time conversion
    return tz.TZDateTime.from(dateTime.toUtc(), pakistanLocation);
  }
}
