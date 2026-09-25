import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/staff_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';

class BookingConflictException implements Exception {
  final String message;
  BookingConflictException([this.message = 'This slot was just booked by another client. Please select another time.']);
  @override
  String toString() => message;
}

class PastSlotException implements Exception {
  final String message;
  PastSlotException([this.message = 'This appointment time has already passed.']);
  @override
  String toString() => message;
}

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of all active salon services (Read-Only Catalog)
  Stream<List<ServiceModel>> streamServices() {
    return _firestore.collection('services').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream of all salon staff members (Read-Only Catalog)
  Stream<List<StaffModel>> streamStaff() {
    return _firestore
        .collection('staff')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList();
    });
  }

  /// Real-time stream of availability slots
  Stream<List<SlotModel>> streamSlots({String? staffId}) {
    Query query = _firestore.collection('slots');
    if (staffId != null && staffId.isNotEmpty) {
      query = query.where('staffId', isEqualTo: staffId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SlotModel.fromFirestore(doc)).toList();
    });
  }

  /// Real-time stream of user bookings (Strict Isolation: Only user's own UID)
  Stream<List<BookingModel>> streamUserBookings(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bookings')
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  /// Atomic Slot Reservation Transaction
  /// Guarantees that two simultaneous users cannot book the same slot.
  /// Reuses client-generated bookingId for idempotency on retries.
  Future<BookingModel> reserveSlotAtomically({
    required String uid,
    required String bookingId,
    required SlotModel slot,
    required ServiceModel service,
    required StaffModel staff,
    String? notes,
  }) async {
    final slotRef = _firestore.collection('slots').doc(slot.id);
    final bookingRef = _firestore.collection('users').doc(uid).collection('bookings').doc(bookingId);

    return await _firestore.runTransaction<BookingModel>((transaction) async {
      // 1. Idempotency Check: Did this booking already succeed on a previous retry?
      final existingBookingDoc = await transaction.get(bookingRef);
      if (existingBookingDoc.exists) {
        return BookingModel.fromFirestore(existingBookingDoc);
      }

      // 2. Fetch the target canonical slot
      final slotDoc = await transaction.get(slotRef);
      if (!slotDoc.exists) {
        throw Exception('The requested slot no longer exists.');
      }

      final slotData = slotDoc.data() as Map<String, dynamic>;
      final isReserved = slotData['isReserved'] as bool? ?? false;

      // 3. Concurrency check: If taken by another user, abort transaction
      if (isReserved) {
        throw BookingConflictException();
      }

      // 4. Past-slot check: Cannot book elapsed slots
      final startAtRaw = slotData['startAt'];
      DateTime startAtDate = DateTime.now();
      if (startAtRaw is Timestamp) {
        startAtDate = startAtRaw.toDate();
      } else if (startAtRaw is String) {
        startAtDate = DateTime.tryParse(startAtRaw) ?? DateTime.now();
      }

      if (startAtDate.isBefore(DateTime.now().toUtc())) {
        throw PastSlotException();
      }

      // 5. Atomically reserve slot (Contains ZERO customer PII)
      transaction.update(slotRef, {
        'isReserved': true,
        'bookingRef': bookingId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 6. Atomically create private booking record in user subcollection
      final newBookingData = {
        'bookingId': bookingId,
        'slotId': slot.id,
        'serviceId': service.id,
        'serviceName': service.name,
        'servicePricePkr': service.pricePkr,
        'staffId': staff.id,
        'staffName': staff.name,
        'startAt': slotData['startAt'],
        'endAt': slotData['endAt'],
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
        'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      };

      transaction.set(bookingRef, newBookingData);

      return BookingModel(
        bookingId: bookingId,
        slotId: slot.id,
        serviceId: service.id,
        serviceName: service.name,
        servicePricePkr: service.pricePkr,
        staffId: staff.id,
        staffName: staff.name,
        startAt: startAtDate,
        endAt: slot.endAt,
        status: BookingStatus.upcoming,
        createdAt: DateTime.now(),
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      );
    });
  }

  /// Atomic Cancellation Transaction
  /// Cancels booking and releases the slot ONLY if the slot still belongs to this booking.
  Future<void> cancelBookingAtomically({
    required String uid,
    required BookingModel booking,
  }) async {
    final slotRef = _firestore.collection('slots').doc(booking.slotId);
    final bookingRef = _firestore.collection('users').doc(uid).collection('bookings').doc(booking.bookingId);

    await _firestore.runTransaction((transaction) async {
      // 1. Fetch user booking
      final bookingDoc = await transaction.get(bookingRef);
      if (!bookingDoc.exists) {
        throw Exception('Booking record not found.');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      if (bookingData['status'] == 'cancelled') {
        return; // Idempotent success
      }

      // 2. Verify start time has not passed
      final startAtRaw = bookingData['startAt'];
      DateTime startAtDate = DateTime.now();
      if (startAtRaw is Timestamp) {
        startAtDate = startAtRaw.toDate();
      }
      if (startAtDate.isBefore(DateTime.now().toUtc())) {
        throw PastSlotException('Cannot cancel appointments that have already started.');
      }

      // 3. Verify slot still belongs to this booking before releasing
      final slotDoc = await transaction.get(slotRef);
      if (slotDoc.exists) {
        final slotData = slotDoc.data() as Map<String, dynamic>;
        if (slotData['bookingRef'] == booking.bookingId) {
          transaction.update(slotRef, {
            'isReserved': false,
            'bookingRef': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 4. Update booking status to cancelled
      transaction.update(bookingRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
