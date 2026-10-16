import 'dart:async';
import 'package:uuid/uuid.dart';
import '../constants/app_enums.dart';
import '../models/payment_model.dart';
import 'api_client.dart';
class PaymentService { PaymentService({ApiClient? api}):_api=api??ApiClient(); final ApiClient _api; final Uuid _uuid=const Uuid();
 Future<PaymentModel> createPayment({required String orderId,required String customerId,required String providerId,required double amount,required PaymentMethod method,required String customerPhone}) async {final r=await _api.post('/api/payments',data:{'id':_uuid.v4(),'orderId':orderId,'customerId':customerId,'providerId':providerId,'amount':amount,'method':method.value,'customerPhone':customerPhone});return PaymentModel.fromMap(r.data['id'].toString(),Map<String,dynamic>.from(r.data));}
 Future<void> markCashCollected(String id)=>_api.put('/api/payments/$id/cash-collected').then((_){});
 Stream<PaymentModel?> watchPayment(String id)=>_poll(() async {try{final r=await _api.get('/api/payments/$id');return PaymentModel.fromMap(id,Map<String,dynamic>.from(r.data));}catch(_){return null;}});
 Stream<List<PaymentModel>> watchPaymentsForOrder(String id)=>_poll(() async {final r=await _api.get('/api/payments',query:{'order_id':id});return (r.data as List).map((e)=>PaymentModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList();});
 Stream<T> _poll<T>(Future<T> Function() load) async*{while(true){yield await load();await Future<void>.delayed(const Duration(seconds:3));}}
}
