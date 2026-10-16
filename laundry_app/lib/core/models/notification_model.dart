import '../services/json_codec.dart';
import 'package:equatable/equatable.dart';

enum NotificationType {
  newOrder,
  orderAccepted,
  orderRejected,
  orderStatusChange,
  paymentConfirmation,
  orderCompleted,
  cancellation,
  providerUpdate,
  general,
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedOrderId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedOrderId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      relatedOrderId: map['relatedOrderId'],
      isRead: map['isRead'] ?? false,
      createdAt: dateFromJson(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'relatedOrderId': relatedOrderId,
        'isRead': isRead,
        'createdAt': dateToJson(createdAt),
      };

  @override
  List<Object?> get props => [id, userId, title, isRead];
}
