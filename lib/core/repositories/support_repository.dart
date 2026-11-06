import 'dart:async';
import '../models/support_message_model.dart';
import '../services/api_client.dart';

class SupportRepository {
  SupportRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<void> sendMessage({
    required String subject,
    required String message,
  }) async {
    await _api.post('/api/support/messages', data: {
      'subject': subject.trim(),
      'message': message.trim(),
    });
  }

  Future<void> setResolved(String id, bool resolved) async {
    await _api.put('/api/support/messages/$id', data: {
      'status': resolved ? 'resolved' : 'open',
    });
  }

  Stream<List<SupportMessageModel>> watchMessages() async* {
    while (true) {
      final response = await _api.get('/api/support/messages');
      yield (response.data as List)
          .map((item) => SupportMessageModel.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
}
