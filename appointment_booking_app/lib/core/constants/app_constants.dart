class AppConstants {
  static const String appName = 'Appointment Booking App';
  
  // Timezone & Business Rules
  static const String businessTimezone = 'Asia/Karachi';
  static const String businessTimezoneLabel = 'PKT';
  static const int businessStartHour = 10; // 10:00 AM
  static const int businessEndHour = 18;   // 6:00 PM
  static const int serviceDurationMinutes = 30; // 30 minutes
  static const int bookingWindowDays = 14; // Today + 13 days
  
  // Last slot starts at 17:30 (5:30 PM)
  static const int lastSlotHour = 17;
  static const int lastSlotMinute = 30;

  // Currency
  static const String currency = 'PKR';

  // Backend Base URL
  static const String defaultBackendUrl = 'http://localhost:5000/api';
}
