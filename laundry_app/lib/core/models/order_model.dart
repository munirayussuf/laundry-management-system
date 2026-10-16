import '../services/json_codec.dart';
import 'package:equatable/equatable.dart';
import '../constants/app_enums.dart';

class OrderAddress extends Equatable {
  final String label;
  final double latitude;
  final double longitude;

  const OrderAddress({required this.label, this.latitude = 0, this.longitude = 0});

  factory OrderAddress.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const OrderAddress(label: '');
    return OrderAddress(
      label: map['label'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  List<Object?> get props => [label, latitude, longitude];
}

/// A single laundry service line inside an order, e.g. Washing And Ironing,
/// 3 kilograms, at 150 KES each.
class OrderItem extends Equatable {
  final String serviceId;
  final String serviceName;
  final double quantity;
  final String pricingUnit;
  final double unitPrice;

  const OrderItem({
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.pricingUnit,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      pricingUnit: map['pricingUnit'] ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'serviceName': serviceName,
        'quantity': quantity,
        'pricingUnit': pricingUnit,
        'unitPrice': unitPrice,
      };

  @override
  List<Object?> get props => [serviceId, quantity, unitPrice];
}

class OrderModel extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String providerId;
  final String providerName;
  final List<OrderItem> items;
  final WashingMethod washingMethod;
  final IroningMethod ironingMethod;
  final bool pickupRequested;
  final bool deliveryRequested;
  final OrderAddress pickupAddress;
  final OrderAddress deliveryAddress;
  final DateTime scheduledDate;
  final String scheduledTime;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.providerName,
    required this.items,
    required this.washingMethod,
    required this.ironingMethod,
    this.pickupRequested = true,
    this.deliveryRequested = true,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.orderStatus = OrderStatus.pending,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      items: ((map['items'] as List?) ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      washingMethod: WashingMethodX.fromString(map['washingMethod'] as String?),
      ironingMethod: IroningMethodX.fromString(map['ironingMethod'] as String?),
      pickupRequested: map['pickupRequested'] ?? true,
      deliveryRequested: map['deliveryRequested'] ?? true,
      pickupAddress: OrderAddress.fromMap(map['pickupLocation']),
      deliveryAddress: OrderAddress.fromMap(map['deliveryLocation']),
      scheduledDate: dateFromJson(map['scheduledDate']),
      scheduledTime: map['scheduledTime'] ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethodX.fromString(map['paymentMethod'] as String?),
      paymentStatus: PaymentStatusX.fromString(map['paymentStatus'] as String?),
      orderStatus: OrderStatusX.fromString(map['orderStatus'] as String?),
      notes: map['notes'] ?? '',
      createdAt: dateFromJson(map['createdAt']),
      updatedAt: dateFromJson(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'providerId': providerId,
      'providerName': providerName,
      'items': items.map((e) => e.toMap()).toList(),
      'washingMethod': washingMethod.value,
      'ironingMethod': ironingMethod.value,
      'pickupRequested': pickupRequested,
      'deliveryRequested': deliveryRequested,
      'pickupLocation': pickupAddress.toMap(),
      'deliveryLocation': deliveryAddress.toMap(),
      'scheduledDate': dateToJson(scheduledDate),
      'scheduledTime': scheduledTime,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.value,
      'paymentStatus': paymentStatus.value,
      'orderStatus': orderStatus.value,
      'notes': notes,
      'createdAt': dateToJson(createdAt),
      'updatedAt': dateToJson(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, customerId, providerId, orderStatus, totalAmount];
}
