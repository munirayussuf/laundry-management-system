import '../services/json_codec.dart';
import 'package:equatable/equatable.dart';

/// A single service offered by a provider, e.g. Washing, Ironing, Washing
/// And Ironing, Pickup, Delivery. Stored as a document inside
/// providers/{providerId}/services/{serviceId}.
class ServiceModel extends Equatable {
  final String id;
  final String providerId;
  final String name;
  final String description;
  final double price;
  final String pricingUnit; // e.g. per kilogram, per piece, per load
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.price,
    required this.pricingUnit,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    return ServiceModel(
      id: id,
      providerId: map['providerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      pricingUnit: map['pricingUnit'] ?? 'per kilogram',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: dateFromJson(map['createdAt']),
      updatedAt: dateFromJson(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'name': name,
      'description': description,
      'price': price,
      'pricingUnit': pricingUnit,
      'isAvailable': isAvailable,
      'createdAt': dateToJson(createdAt),
      'updatedAt': dateToJson(updatedAt),
    };
  }

  ServiceModel copyWith({
    String? name,
    String? description,
    double? price,
    String? pricingUnit,
    bool? isAvailable,
  }) {
    return ServiceModel(
      id: id,
      providerId: providerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      pricingUnit: pricingUnit ?? this.pricingUnit,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, providerId, name, price, isAvailable];
}
