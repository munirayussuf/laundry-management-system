import '../services/json_codec.dart';
import 'package:equatable/equatable.dart';
import '../constants/app_enums.dart';

class PaymentModel extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final String providerId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? providerReference; // e.g. mobile money transaction code
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.providerId,
    required this.amount,
    required this.method,
    this.status = PaymentStatus.pending,
    this.providerReference,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      orderId: map['orderId'] ?? '',
      customerId: map['customerId'] ?? '',
      providerId: map['providerId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      method: PaymentMethodX.fromString(map['method'] as String?),
      status: PaymentStatusX.fromString(map['status'] as String?),
      providerReference: map['providerReference'],
      failureReason: map['failureReason'],
      createdAt: dateFromJson(map['createdAt']),
      updatedAt: dateFromJson(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'customerId': customerId,
        'providerId': providerId,
        'amount': amount,
        'method': method.value,
        'status': status.value,
        'providerReference': providerReference,
        'failureReason': failureReason,
        'createdAt': dateToJson(createdAt),
        'updatedAt': dateToJson(updatedAt),
      };

  @override
  List<Object?> get props => [id, orderId, status, amount];
}
