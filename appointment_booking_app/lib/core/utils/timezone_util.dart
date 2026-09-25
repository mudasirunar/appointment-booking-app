import 'package:intl/intl.dart';

/// Utilities for handling business timezone logic.
/// The salon operates strictly in Asia/Karachi (PKT, UTC+5).
class TimezoneUtil {
  // Asia/Karachi is standard UTC+5 (5 hours ahead of UTC) with no Daylight Saving Time
  static const Duration pktOffset = Duration(hours: 5);
  static const String timezoneLabel = 'PKT';

  /// Returns current DateTime anchored to Asia/Karachi (PKT)
  static DateTime nowInPkt() {
    return DateTime.now().toUtc().add(pktOffset);
  }

  /// Converts any UTC DateTime into PKT representation
  static DateTime toPkt(DateTime utcDateTime) {
    return utcDateTime.toUtc().add(pktOffset);
  }

  /// Converts a PKT representation DateTime back into UTC
  static DateTime pktToUtc(DateTime pktDateTime) {
    return pktDateTime.subtract(pktOffset);
  }

  /// Returns true if the day is Sunday (business is closed)
  static bool isSunday(DateTime date) {
    return date.weekday == DateTime.sunday;
  }

  /// Checks if a slot's UTC start time has already passed relative to current time
  static bool isPastSlot(DateTime slotStartUtc) {
    return slotStartUtc.toUtc().isBefore(DateTime.now().toUtc());
  }

  /// Returns the 14 calendar dates (today + 13 days) in PKT
  static List<DateTime> get14CalendarDays() {
    final nowPkt = nowInPkt();
    final today = DateTime.utc(nowPkt.year, nowPkt.month, nowPkt.day);
    return List.generate(14, (index) => today.add(Duration(days: index)));
  }

  /// Format: "10:30 AM (PKT)"
  static String formatTimeWithTimezone(DateTime utcDateTime) {
    final pkt = toPkt(utcDateTime);
    final timeStr = DateFormat('h:mm a').format(pkt);
    return '$timeStr ($timezoneLabel)';
  }

  /// Format: "Sat, Sep 26, 2026"
  static String formatDate(DateTime utcDateTime) {
    final pkt = toPkt(utcDateTime);
    return DateFormat('EEE, MMM d, yyyy').format(pkt);
  }

  /// Format: "Sat, Sep 26 at 10:30 AM (PKT)"
  static String formatFullDateTime(DateTime utcDateTime) {
    final pkt = toPkt(utcDateTime);
    final dateStr = DateFormat('EEE, MMM d').format(pkt);
    final timeStr = DateFormat('h:mm a').format(pkt);
    return '$dateStr at $timeStr ($timezoneLabel)';
  }

  /// Short day name: "Mon", "Tue", etc.
  static String formatDayShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Day of month: "26"
  static String formatDayNumber(DateTime date) {
    return DateFormat('d').format(date);
  }

  /// Month short name: "Sep"
  static String formatMonthShort(DateTime date) {
    return DateFormat('MMM').format(date);
  }
}
