import 'dart:async';
import 'package:uuid/uuid.dart';
import '../constants/app_enums.dart';
import '../models/order_model.dart';
import '../services/api_client.dart';
class OrderRepository {
  OrderRepository({ApiClient? api}):_api=api??ApiClient(); final ApiClient _api; final Uuid _uuid=const Uuid();
  Future<OrderModel> createOrder({required String customerId,required String customerName,required String providerId,required String providerName,required List<OrderItem> items,required WashingMethod washingMethod,required IroningMethod ironingMethod,required bool pickupRequested,required bool deliveryRequested,required OrderAddress pickupAddress,required OrderAddress deliveryAddress,required DateTime scheduledDate,required String scheduledTime,required PaymentMethod paymentMethod,String notes=''}) async { if(items.isEmpty) throw ArgumentError('An order must contain at least one laundry service.'); final r=await _api.post('/api/orders',data:{'customerId':customerId,'customerName':customerName,'providerId':providerId,'providerName':providerName,'items':items.map((e)=>e.toMap()).toList(),'washingMethod':washingMethod.value,'ironingMethod':ironingMethod.value,'pickupRequested':pickupRequested,'deliveryRequested':deliveryRequested,'pickupLocation':pickupAddress.toMap(),'deliveryLocation':deliveryAddress.toMap(),'scheduledDate':scheduledDate.toIso8601String(),'scheduledTime':scheduledTime,'paymentMethod':paymentMethod.value,'notes':notes}); return OrderModel.fromMap(r.data['id'].toString(),Map<String,dynamic>.from(r.data)); }
  Stream<OrderModel?> watchOrder(String id)=>_poll(() async { try{final r=await _api.get('/api/orders/$id');return OrderModel.fromMap(id,Map<String,dynamic>.from(r.data));}catch(_){return null;} });
  Stream<List<OrderModel>> watchCustomerOrders(String id)=>_list('/api/orders',{'customer_id':id});
  Stream<List<OrderModel>> watchProviderOrders(String id,{OrderStatus? status})=>_list('/api/orders',{'provider_id':id,'status':status?.value});
  Future<void> updateStatus(String id,OrderStatus status)=>_api.put('/api/orders/$id/status',data:{'status':status.value}).then((_){});
  Future<void> updatePaymentStatus(String id,PaymentStatus status)=>_api.put('/api/orders/$id/payment-status',data:{'status':status.value}).then((_){});
  Future<void> cancelOrder(String id)=>updateStatus(id,OrderStatus.cancelled);
  Future<void> deleteOrder(String id)=>_api.delete('/api/orders/$id').then((_){});
  Future<List<OrderModel>> allOrdersOnce() async {final r=await _api.get('/api/orders');return (r.data as List).map((e)=>OrderModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList();}
  Stream<List<OrderModel>> watchAllOrders()=>_poll(() async {final r=await _api.get('/api/orders');return (r.data as List).map((e)=>OrderModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList();});
  Stream<List<OrderModel>> _list(String path,Map<String,dynamic> q)=>_poll(() async {final r=await _api.get(path,query:q);return (r.data as List).map((e)=>OrderModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList();});
  Stream<T> _poll<T>(Future<T> Function() load) async*{while(true){yield await load();await Future<void>.delayed(const Duration(seconds:3));}}
}
