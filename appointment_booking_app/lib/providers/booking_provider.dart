import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../models/staff_model.dart';
import '../models/slot_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final Uuid _uuid = const Uuid();

  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isCancelling = false;
  String? _errorMessage;

  // Active booking attempt (Idempotency key)
  String? _activeBookingId;

  StreamSubscription<List<BookingModel>>? _bookingsSubscription;
  String? _currentUid;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;

  /// Upcoming bookings sorted ascending by start time (soonest first)
  List<BookingModel> get upcomingBookings {
    return _bookings
        .where((b) => b.status == BookingStatus.upcoming)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  /// Past bookings sorted descending by start time (most recent past first)
  List<BookingModel> get pastBookings {
    return _bookings
        .where((b) => b.status == BookingStatus.past)
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  /// Cancelled bookings sorted descending by cancellation timestamp
  List<BookingModel> get cancelledBookings {
    return _bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .toList()
      ..sort((a, b) {
        final aTime = a.cancelledAt ?? a.createdAt;
        final bTime = b.cancelledAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
  }

  /// Bind listeners to the authenticated user's bookings (Account Isolation)
  void bindUser(String uid) {
    if (_currentUid == uid) return;
    unbindUser(); // Clear previous listeners immediately
    _currentUid = uid;
    _isLoading = true;
    notifyListeners();

    _bookingsSubscription = _bookingService.streamUserBookings(uid).listen(
      (bookings) {
        _bookings = bookings;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load bookings.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Unbind and clear on sign out (Section 05 of assignment: immediate state teardown)
  void unbindUser() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
    _bookings.clear();
    _currentUid = null;
    _activeBookingId = null;
    _isLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Generates or reuses unique booking reference for idempotent retry
  String getOrCreateBookingId() {
    _activeBookingId ??= 'BK-${_uuid.v4().substring(0, 8).toUpperCase()}';
    return _activeBookingId!;
  }

  /// Reset booking attempt ID after confirmed completion
  void resetActiveBookingId() {
    _activeBookingId = null;
  }

  /// Atomic Slot Reservation with double-tap debounce & idempotent retry
  Future<BookingModel?> confirmBooking({
    required String uid,
    required SlotModel slot,
    required ServiceModel service,
    required StaffModel staff,
  }) async {
    if (_isSubmitting) return null; // Double-tap protection
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final bookingId = getOrCreateBookingId();

    try {
      final booking = await _bookingService.reserveSlotAtomically(
        uid: uid,
        bookingId: bookingId,
        slot: slot,
        service: service,
        staff: staff,
      );

      _isSubmitting = false;
      resetActiveBookingId(); // Completed successfully
      notifyListeners();
      return booking;
    } on BookingConflictException catch (e) {
      _isSubmitting = false;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } on PastSlotException catch (e) {
      _isSubmitting = false;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Connection interrupted. Please tap retry.';
      notifyListeners();
      rethrow;
    }
  }

  /// Atomic Cancellation
  Future<bool> cancelBooking({
    required String uid,
    required BookingModel booking,
  }) async {
    if (_isCancelling) return false;
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookingService.cancelBookingAtomically(
        uid: uid,
        booking: booking,
      );
      _isCancelling = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isCancelling = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }
}
