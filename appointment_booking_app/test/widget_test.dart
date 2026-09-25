import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_booking_app/core/utils/timezone_util.dart';
import 'package:appointment_booking_app/models/service_model.dart';
import 'package:appointment_booking_app/models/slot_model.dart';
import 'package:appointment_booking_app/models/booking_model.dart';
import 'package:appointment_booking_app/services/booking_service.dart';

void main() {
  group('Timezone & Domain Tests (Asia/Karachi PKT UTC+5)', () {
    test('14 calendar days generation returns exactly 14 dates', () {
      final days = TimezoneUtil.get14CalendarDays();
      expect(days.length, 14);
      expect(days.first.isBefore(days.last), isTrue);
    });

    test('Sunday detection works accurately', () {
      // Find any Sunday in the 14-day window
      final days = TimezoneUtil.get14CalendarDays();
      final sundays = days.where((d) => TimezoneUtil.isSunday(d)).toList();
      expect(sundays.isNotEmpty, isTrue);
      for (final sunday in sundays) {
        expect(sunday.weekday, DateTime.sunday);
        expect(TimezoneUtil.isSunday(sunday), isTrue);
      }
    });

    test('ServiceModel serialization and formatting', () {
      final service = ServiceModel(
        id: 'service_haircut_styling',
        name: 'Haircut & Styling',
        description: 'Precision scissor cut',
        durationMinutes: 30,
        pricePkr: 2500,
        imageUrl: 'https://example.com/haircut.jpg',
      );

      expect(service.formattedPrice, 'PKR 2,500');
      expect(service.displayImageUrl, 'https://example.com/haircut.jpg');

      final json = service.toJson();
      final fromJson = ServiceModel.fromJson(json);
      expect(fromJson.id, service.id);
      expect(fromJson.name, service.name);
      expect(fromJson.pricePkr, 2500);
      expect(fromJson.durationMinutes, 30);
    });

    test('SlotModel formatting and past status', () {
      final futureStart = DateTime.now().toUtc().add(const Duration(days: 2));
      final futureEnd = futureStart.add(const Duration(minutes: 30));

      final slot = SlotModel(
        id: 'staff_1_2026-09-27T10:00:00Z',
        staffId: 'staff_1',
        staffName: 'Hamza Khan',
        startAt: futureStart,
        endAt: futureEnd,
        isReserved: false,
      );

      expect(slot.isPast, isFalse);
      expect(slot.formattedTime.contains(TimezoneUtil.timezoneLabel), isTrue);
    });

    test('BookingModel serialization and formatted values', () {
      final now = DateTime.now().toUtc();
      final start = now.add(const Duration(days: 1));
      final end = start.add(const Duration(minutes: 30));

      final booking = BookingModel(
        bookingId: 'BK-TEST01',
        slotId: 'staff_1_slot_123',
        serviceId: 'service_haircut_styling',
        serviceName: 'Haircut & Styling',
        servicePricePkr: 2500,
        staffId: 'staff_1',
        staffName: 'Hamza Khan',
        startAt: start,
        endAt: end,
        status: BookingStatus.upcoming,
        createdAt: now,
        notes: 'Low fade on sides please',
      );

      expect(booking.formattedPrice, 'PKR 2,500');
      expect(booking.notes, 'Low fade on sides please');
      expect(booking.status, BookingStatus.upcoming);

      final json = booking.toJson();
      expect(json['bookingId'], 'BK-TEST01');
      expect(json['servicePricePkr'], 2500);
      expect(json['notes'], 'Low fade on sides please');
    });

    test('BookingConflictException and PastSlotException have descriptive messages', () {
      final conflict = BookingConflictException();
      expect(conflict.message.contains('booked by another client'), isTrue);

      final past = PastSlotException();
      expect(past.message.contains('already passed'), isTrue);
    });
  });
}
