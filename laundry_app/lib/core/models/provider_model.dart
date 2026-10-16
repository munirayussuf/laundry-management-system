import '../services/json_codec.dart';
import 'package:equatable/equatable.dart';
import '../constants/app_enums.dart';

/// A laundry provider. This single model represents both Formal Laundry
/// businesses and Mama Fua / Jua Kali operators, distinguished by
/// [providerType]. Every field that matters for discovery and booking is
/// stored directly on the document so provider discovery can be done with a
/// single Firestore query rather than joins.
class ProviderModel extends Equatable {
  final String id;
  final String ownerId;
  final String providerName;
  final ProviderType providerType;
  final WashingMethod washingMethod;
  final IroningMethod ironingMethod;
  final String phone;
  final String email;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String profileImage;
  final double rating;
  final int reviewCount;
  final int dailyCapacity;
  final Map<String, dynamic> workingHours; // e.g. {"open": "07:00", "close": "19:00"}
  final bool isAvailable;
  final bool isVerified;
  final bool isActive;
  final double startingPrice;
  final int turnaroundHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProviderModel({
    required this.id,
    required this.ownerId,
    required this.providerName,
    required this.providerType,
    required this.washingMethod,
    required this.ironingMethod,
    required this.phone,
    required this.email,
    this.description = '',
    this.location = '',
    this.latitude = 0,
    this.longitude = 0,
    this.profileImage = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.dailyCapacity = 0,
    this.workingHours = const {'open': '07:00', 'close': '19:00'},
    this.isAvailable = true,
    this.isVerified = false,
    this.isActive = true,
    this.startingPrice = 0,
    this.turnaroundHours = 24,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMamaFua => providerType == ProviderType.mamaFua;

  factory ProviderModel.fromMap(String id, Map<String, dynamic> map) {
    return ProviderModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      providerName: map['providerName'] ?? '',
      providerType: ProviderTypeX.fromString(map['providerType'] as String?),
      washingMethod: WashingMethodX.fromString(map['washingMethod'] as String?),
      ironingMethod: IroningMethodX.fromString(map['ironingMethod'] as String?),
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      profileImage: map['profileImage'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['reviewCount'] ?? 0,
      dailyCapacity: map['capacity'] ?? 0,
      workingHours: Map<String, dynamic>.from(
        map['workingHours'] ?? {'open': '07:00', 'close': '19:00'},
      ),
      isAvailable: map['availability'] ?? true,
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      startingPrice: (map['startingPrice'] as num?)?.toDouble() ?? 0,
      turnaroundHours: map['turnaroundHours'] ?? 24,
      createdAt: dateFromJson(map['createdAt']),
      updatedAt: dateFromJson(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'providerName': providerName,
      'providerType': providerType.value,
      'washingMethod': washingMethod.value,
      'ironingMethod': ironingMethod.value,
      'phone': phone,
      'email': email,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'profileImage': profileImage,
      'rating': rating,
      'reviewCount': reviewCount,
      'capacity': dailyCapacity,
      'workingHours': workingHours,
      'availability': isAvailable,
      'isVerified': isVerified,
      'isActive': isActive,
      'startingPrice': startingPrice,
      'turnaroundHours': turnaroundHours,
      'createdAt': dateToJson(createdAt),
      'updatedAt': dateToJson(updatedAt),
    };
  }

  ProviderModel copyWith({
    String? providerName,
    ProviderType? providerType,
    WashingMethod? washingMethod,
    IroningMethod? ironingMethod,
    String? phone,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? profileImage,
    double? rating,
    int? reviewCount,
    int? dailyCapacity,
    Map<String, dynamic>? workingHours,
    bool? isAvailable,
    bool? isVerified,
    bool? isActive,
    double? startingPrice,
    int? turnaroundHours,
  }) {
    return ProviderModel(
      id: id,
      ownerId: ownerId,
      providerName: providerName ?? this.providerName,
      providerType: providerType ?? this.providerType,
      washingMethod: washingMethod ?? this.washingMethod,
      ironingMethod: ironingMethod ?? this.ironingMethod,
      phone: phone ?? this.phone,
      email: email,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      dailyCapacity: dailyCapacity ?? this.dailyCapacity,
      workingHours: workingHours ?? this.workingHours,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      startingPrice: startingPrice ?? this.startingPrice,
      turnaroundHours: turnaroundHours ?? this.turnaroundHours,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, ownerId, providerName, providerType, isActive, rating];
}
