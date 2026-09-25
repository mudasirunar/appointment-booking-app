import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final bool active;

  const StaffModel({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    this.active = true,
  });

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StaffModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Staff Member',
      role: data['role'] as String? ?? 'Stylist',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      active: data['active'] as bool? ?? true,
    );
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Staff Member',
      role: json['role'] as String? ?? 'Stylist',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'active': active,
    };
  }
}
