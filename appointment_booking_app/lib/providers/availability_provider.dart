import 'dart:async';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/staff_model.dart';
import '../models/slot_model.dart';
import '../services/booking_service.dart';
import '../core/utils/timezone_util.dart';

class AvailabilityProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<ServiceModel> _services = [];
  List<StaffModel> _staffList = [];
  List<SlotModel> _allSlots = [];

  ServiceModel? _selectedService;
  StaffModel? _selectedStaff;
  DateTime _selectedDate = TimezoneUtil.get14CalendarDays().first;
  SlotModel? _selectedSlot;

  bool _isLoadingServices = true;
  bool _isLoadingStaff = true;
  bool _isLoadingSlots = true;
  String? _errorMessage;

  StreamSubscription? _servicesSub;
  StreamSubscription? _staffSub;
  StreamSubscription? _slotsSub;

  AvailabilityProvider() {
    _initCatalogStreams();
  }

  // Getters
  List<ServiceModel> get services => _services;
  List<StaffModel> get staffList => _staffList;
  ServiceModel? get selectedService => _selectedService;
  StaffModel? get selectedStaff => _selectedStaff;
  DateTime get selectedDate => _selectedDate;
  SlotModel? get selectedSlot => _selectedSlot;

  bool get isLoading => _isLoadingServices || _isLoadingStaff || _isLoadingSlots;
  bool get isLoadingServices => _isLoadingServices;
  bool get isLoadingSlots => _isLoadingSlots;
  String? get errorMessage => _errorMessage;

  bool get isSelectedDateSunday => TimezoneUtil.isSunday(_selectedDate);

  /// Available slots for selected staff and date in PKT timezone (excluding past slots)
  List<SlotModel> get visibleSlots {
    if (isSelectedDateSunday) return [];
    if (_selectedStaff == null) return [];

    final targetPktDate = _selectedDate;

    return _allSlots.where((slot) {
      // Must match selected staff
      if (slot.staffId != _selectedStaff!.id) return false;

      // Must match selected PKT date
      final slotPkt = TimezoneUtil.toPkt(slot.startAt);
      final isSameDay = slotPkt.year == targetPktDate.year &&
          slotPkt.month == targetPktDate.month &&
          slotPkt.day == targetPktDate.day;
      if (!isSameDay) return false;

      // Must not be in the past
      if (slot.isPast) return false;

      return true;
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  void _initCatalogStreams() {
    _servicesSub = _bookingService.streamServices().listen(
      (services) {
        _services = services;
        if (_selectedService == null && services.isNotEmpty) {
          _selectedService = services.first;
        }
        _isLoadingServices = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load services.';
        _isLoadingServices = false;
        notifyListeners();
      },
    );

    _staffSub = _bookingService.streamStaff().listen(
      (staff) {
        _staffList = staff;
        if (_selectedStaff == null && staff.isNotEmpty) {
          _selectedStaff = staff.first;
        }
        _isLoadingStaff = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load staff.';
        _isLoadingStaff = false;
        notifyListeners();
      },
    );

    _slotsSub = _bookingService.streamSlots().listen(
      (slots) {
        _allSlots = slots;
        _isLoadingSlots = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load availability.';
        _isLoadingSlots = false;
        notifyListeners();
      },
    );
  }

  void selectService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  void selectStaff(StaffModel staff) {
    _selectedStaff = staff;
    _selectedSlot = null; // Reset slot selection when staff changes
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedSlot = null; // Reset slot selection when date changes
    notifyListeners();
  }

  void selectSlot(SlotModel slot) {
    if (slot.isReserved || slot.isPast) return;
    _selectedSlot = slot;
    notifyListeners();
  }

  void clearSelection() {
    _selectedSlot = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _servicesSub?.cancel();
    _staffSub?.cancel();
    _slotsSub?.cancel();
    super.dispose();
  }
}
