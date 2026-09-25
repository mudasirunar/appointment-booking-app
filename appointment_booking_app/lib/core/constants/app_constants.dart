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

  // Backend Base URL & Security
  static const String defaultBackendUrl = 'https://appointment-booking-app-seven.vercel.app/api';
  static const String appSecretToken = 'salon_sec_9a87d6f5e4c3b2a1';
}
