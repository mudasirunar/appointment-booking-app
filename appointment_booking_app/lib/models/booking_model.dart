import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/timezone_util.dart';

enum BookingStatus { upcoming, past, cancelled }

class BookingModel {
  final String bookingId;
  final String slotId;
  final String serviceId;
  final String serviceName;
  final int servicePricePkr;
  final String staffId;
  final String staffName;
  final DateTime startAt;
  final DateTime endAt;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? notes;
  final String paymentStatus;
  final String paymentMethod;
  final String transactionId;
  final int amountPaid;
  final DateTime? paidAt;
  final String? paymentDetails;

  const BookingModel({
    required this.bookingId,
    required this.slotId,
    required this.serviceId,
    required this.serviceName,
    required this.servicePricePkr,
    required this.staffId,
    required this.staffName,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
    this.notes,
    this.paymentStatus = 'paid',
    this.paymentMethod = 'card',
    this.transactionId = '',
    this.amountPaid = 0,
    this.paidAt,
    this.paymentDetails,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableTimestamp(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawStatus = data['status'] as String? ?? 'upcoming';
    final startAt = parseTimestamp(data['startAt']);
    
    // Compute dynamic status: If status is not cancelled, check if startAt has passed
    BookingStatus computedStatus;
    if (rawStatus == 'cancelled') {
      computedStatus = BookingStatus.cancelled;
    } else if (TimezoneUtil.isPastSlot(startAt)) {
      computedStatus = BookingStatus.past;
    } else {
      computedStatus = BookingStatus.upcoming;
    }

    final price = (data['servicePricePkr'] as num?)?.toInt() ?? 0;
    final fallbackTxn = 'TXN-${doc.id.length >= 8 ? doc.id.substring(0, 8).toUpperCase() : doc.id.toUpperCase()}';

    return BookingModel(
      bookingId: doc.id,
      slotId: data['slotId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? 'Service',
      servicePricePkr: price,
      staffId: data['staffId'] as String? ?? '',
      staffName: data['staffName'] as String? ?? 'Staff Member',
      startAt: startAt,
      endAt: parseTimestamp(data['endAt']),
      status: computedStatus,
      createdAt: parseTimestamp(data['createdAt']),
      cancelledAt: parseNullableTimestamp(data['cancelledAt']),
      notes: data['notes'] as String?,
      paymentStatus: data['paymentStatus'] as String? ?? 'paid',
      paymentMethod: data['paymentMethod'] as String? ?? 'card',
      transactionId: data['transactionId'] as String? ?? fallbackTxn,
      amountPaid: (data['amountPaid'] as num?)?.toInt() ?? price,
      paidAt: parseNullableTimestamp(data['paidAt']) ?? parseTimestamp(data['createdAt']),
      paymentDetails: data['paymentDetails'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'slotId': slotId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePricePkr': servicePricePkr,
      'staffId': staffId,
      'staffName': staffName,
      'startAt': startAt.toUtc(),
      'endAt': endAt.toUtc(),
      'status': status.name,
      'createdAt': createdAt.toUtc(),
      'cancelledAt': cancelledAt?.toUtc(),
      'notes': notes,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'amountPaid': amountPaid,
      'paidAt': paidAt?.toUtc(),
      'paymentDetails': paymentDetails,
    };
  }

  String get formattedPrice => 'PKR ${servicePricePkr.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  String get formattedDateTime => TimezoneUtil.formatFullDateTime(startAt);
  String get formattedDate => TimezoneUtil.formatDate(startAt);
  String get formattedTime => TimezoneUtil.formatTimeWithTimezone(startAt);

  bool get canCancel => status == BookingStatus.upcoming && !TimezoneUtil.isPastSlot(startAt);
}
