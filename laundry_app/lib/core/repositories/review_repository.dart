import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';
import '../services/api_client.dart';
import 'provider_repository.dart';
class ReviewRepository { ReviewRepository({ApiClient? api,ProviderRepository? providerRepository}):_api=api??ApiClient(),_providerRepository=providerRepository??ProviderRepository(api:api); final ApiClient _api; final ProviderRepository _providerRepository; final Uuid _uuid=const Uuid();
 Stream<List<ReviewModel>> watchForProvider(String id)=>_poll(() async {final r=await _api.get('/api/reviews',query:{'provider_id':id});return (r.data as List).map((e)=>ReviewModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList();});
 Future<void> submitReview({required String orderId,required String customerId,required String customerName,required String providerId,required int rating,required String comment}) async {await _api.post('/api/reviews',data:{'id':_uuid.v4(),'orderId':orderId,'customerId':customerId,'customerName':customerName,'providerId':providerId,'rating':rating,'comment':comment});}
 Future<void> deleteReview(String id)=>_api.delete('/api/reviews/$id').then((_){});
 Stream<T> _poll<T>(Future<T> Function() load) async*{while(true){yield await load();await Future<void>.delayed(const Duration(seconds:3));}}
}
