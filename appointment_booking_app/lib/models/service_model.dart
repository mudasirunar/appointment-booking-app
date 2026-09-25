import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final int pricePkr;

  final String? imageUrl;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.pricePkr,
    this.imageUrl,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Service',
      description: data['description'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      pricePkr: (data['pricePkr'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Service',
      description: json['description'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      pricePkr: (json['pricePkr'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'pricePkr': pricePkr,
      'imageUrl': imageUrl,
    };
  }

  /// Curated high-resolution fallback image URL per service
  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return imageUrl!;
    }
    switch (id) {
      case 'service_haircut_styling':
        return 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=80';
      case 'service_beard_grooming':
        return 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=800&q=80';
      case 'service_facial_refresh':
        return 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&w=800&q=80';
      default:
        return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80';
    }
  }

  String get formattedPrice => 'PKR ${pricePkr.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}
