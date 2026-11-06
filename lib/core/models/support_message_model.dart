import '../services/json_codec.dart';

class SupportMessageModel {
  const SupportMessageModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  factory SupportMessageModel.fromMap(Map<String, dynamic> map) {
    return SupportMessageModel(
      id: map['id'].toString(),
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'open',
      createdAt: dateFromJson(map['createdAt']),
    );
  }
}
