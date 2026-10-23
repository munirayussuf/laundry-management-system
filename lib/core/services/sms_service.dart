import 'package:logger/logger.dart';
import 'api_client.dart';
class SmsService { SmsService({ApiClient? api}):_api=api??ApiClient(); final ApiClient _api; final Logger _logger=Logger();
 Future<bool> _send({required String phone,required String message}) async {try{final r=await _api.post('/api/notifications/sms',data:{'phone':phone,'message':message});return r.data['success']==true;}catch(e){_logger.w('SMS send failed: $e');return false;}}
 Future<bool> sendOrderConfirmation(String phone,String orderId,double amount)=>_send(phone:phone,message:'Your laundry order $orderId has been received. Total amount is KES ${amount.toStringAsFixed(0)}. Thank you for choosing us.');
 Future<bool> sendOrderAccepted(String phone,String orderId,String providerName)=>_send(phone:phone,message:'Good news. $providerName has accepted your order $orderId.');
 Future<bool> sendOrderReady(String phone,String orderId)=>_send(phone:phone,message:'Your laundry order $orderId is ready. Delivery will be arranged shortly.');
 Future<bool> sendOrderCompleted(String phone,String orderId)=>_send(phone:phone,message:'Your laundry order $orderId has been completed. Thank you for your business.');
 Future<bool> sendPaymentConfirmation(String phone,double amount)=>_send(phone:phone,message:'Payment of KES ${amount.toStringAsFixed(0)} has been confirmed. Thank you.');
 Future<bool> sendCancellation(String phone,String orderId)=>_send(phone:phone,message:'Your laundry order $orderId has been cancelled.');
}
