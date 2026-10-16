import '../services/json_codec.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String providerId;
  final int rating; // 1 to 5
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      orderId: map['orderId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      providerId: map['providerId'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: dateFromJson(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'customerId': customerId,
        'customerName': customerName,
        'providerId': providerId,
        'rating': rating,
        'comment': comment,
        'createdAt': dateToJson(createdAt),
      };

  @override
  List<Object?> get props => [id, orderId, customerId, rating];
}
