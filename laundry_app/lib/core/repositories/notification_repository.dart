import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../services/api_client.dart';
class NotificationRepository { NotificationRepository({ApiClient? api}):_api=api??ApiClient(); final ApiClient _api; final Uuid _uuid=const Uuid();
 Future<void> create({required String userId,required String title,required String body,required NotificationType type,String? relatedOrderId})=>_api.post('/api/notifications',data:{'id':_uuid.v4(),'userId':userId,'title':title,'body':body,'type':type.name,'relatedOrderId':relatedOrderId}).then((_){});
 Stream<List<NotificationModel>> watchForUser(String userId)=>_poll(() async {final r=await _api.get('/api/notifications',query:{'user_id':userId});return (r.data as List).map((e)=>NotificationModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList();});
 Future<void> markAsRead(String id)=>_api.put('/api/notifications/$id/read').then((_){});
 Future<void> markAllAsRead(String userId)=>_api.put('/api/notifications/read-all',data:{'userId':userId}).then((_){});
 Future<void> delete(String id)=>_api.delete('/api/notifications/$id').then((_){});
 Future<void> clearAll(String userId)=>_api.delete('/api/notifications/user/$userId').then((_){});
 Stream<T> _poll<T>(Future<T> Function() load) async*{while(true){yield await load();await Future<void>.delayed(const Duration(seconds:3));}}
}
