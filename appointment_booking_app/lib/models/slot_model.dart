import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/timezone_util.dart';

class SlotModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime startAt;
  final DateTime endAt;
  final bool isReserved;
  final String? bookingRef;

  const SlotModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.startAt,
    required this.endAt,
    required this.isReserved,
    this.bookingRef,
  });

  factory SlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is Map && val['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch((val['_seconds'] as int) * 1000);
      }
      return DateTime.now();
    }

    return SlotModel(
      id: doc.id,
      staffId: data['staffId'] as String? ?? '',
      staffName: data['staffName'] as String? ?? '',
      startAt: parseTimestamp(data['startAt']),
      endAt: parseTimestamp(data['endAt']),
      isReserved: data['isReserved'] as bool? ?? false,
      bookingRef: data['bookingRef'] as String?,
    );
  }

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is Map && val['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch((val['_seconds'] as int) * 1000);
      }
      return DateTime.now();
    }

    return SlotModel(
      id: json['id'] as String? ?? '',
      staffId: json['staffId'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      startAt: parseDate(json['startAt']),
      endAt: parseDate(json['endAt']),
      isReserved: json['isReserved'] as bool? ?? false,
      bookingRef: json['bookingRef'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'isReserved': isReserved,
      'bookingRef': bookingRef,
    };
  }

  /// True if the slot has already started relative to now
  bool get isPast => TimezoneUtil.isPastSlot(startAt);

  /// Formatted time string, e.g. "10:30 AM (PKT)"
  String get formattedTime => TimezoneUtil.formatTimeWithTimezone(startAt);
}
