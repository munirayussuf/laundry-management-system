import 'dart:async';
import 'package:uuid/uuid.dart';
import '../constants/app_enums.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import '../services/api_client.dart';

class ProviderRepository {
  ProviderRepository({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;
  final Uuid _uuid = const Uuid();

  Future<ProviderModel> registerProvider({required String ownerId, required String providerName, required String phone, required String email, required ProviderType providerType, required WashingMethod washingMethod, required IroningMethod ironingMethod, required String description, required String location, double latitude = 0, double longitude = 0, required double startingPrice, required int turnaroundHours, required int dailyCapacity}) async {
    final r = await _api.post('/api/providers', data: {'ownerId':ownerId,'providerName':providerName,'phone':phone,'email':email,'providerType':providerType.value,'washingMethod':washingMethod.value,'ironingMethod':ironingMethod.value,'description':description,'location':location,'latitude':latitude,'longitude':longitude,'startingPrice':startingPrice,'turnaroundHours':turnaroundHours,'dailyCapacity':dailyCapacity});
    return ProviderModel.fromMap(r.data['id'].toString(), Map<String,dynamic>.from(r.data));
  }
  Future<ProviderModel?> getProvider(String id) async { try { final r=await _api.get('/api/providers/$id'); return ProviderModel.fromMap(id, Map<String,dynamic>.from(r.data)); } catch (_) { return null; } }
  Stream<ProviderModel?> watchProvider(String id) => _poll(() => getProvider(id));
  Stream<List<ProviderModel>> discoverProviders({ProviderType? providerType, WashingMethod? washingMethod, IroningMethod? ironingMethod, bool onlyActive=true, bool onlyAvailable=false}) => _pollList(() async { final r=await _api.get('/api/providers', query:{'provider_type':providerType?.value,'washing_method':washingMethod?.value,'ironing_method':ironingMethod?.value,'only_active':onlyActive,'only_available':onlyAvailable}); return (r.data as List).map((e)=>ProviderModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList(); });
  Stream<List<ProviderModel>> searchProviders(String query) => _pollList(() async { final r=await _api.get('/api/providers', query:{'search':query,'only_active':true}); return (r.data as List).map((e)=>ProviderModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList(); });
  Future<void> updateProvider(String id, Map<String,dynamic> fields) => _api.put('/api/providers/$id', data: fields).then((_){});
  Future<void> setAvailability(String id,bool v)=>updateProvider(id,{'availability':v});
  Future<void> setVerified(String id,bool v)=>updateProvider(id,{'isVerified':v});
  Future<void> setActive(String id,bool v)=>updateProvider(id,{'isActive':v});
  Future<void> deleteProvider(String id)=>_api.delete('/api/providers/$id').then((_){});
  Future<void> recalculateRating(String id,double avg,int count)=>updateProvider(id,{'rating':avg,'reviewCount':count});
  Stream<List<ServiceModel>> watchServices(String providerId)=>_pollList(() async { final r=await _api.get('/api/providers/$providerId/services'); return (r.data as List).map((e)=>ServiceModel.fromMap(e['id'].toString(),Map<String,dynamic>.from(e))).toList(); });
  Future<ServiceModel> addService({required String providerId,required String name,required String description,required double price,required String pricingUnit}) async { final id=_uuid.v4(); final r=await _api.post('/api/providers/$providerId/services',data:{'id':id,'providerId':providerId,'name':name,'description':description,'price':price,'pricingUnit':pricingUnit}); return ServiceModel.fromMap(r.data['id'].toString(),Map<String,dynamic>.from(r.data)); }
  Future<void> editService(String providerId,ServiceModel service)=>_api.put('/api/providers/$providerId/services/${service.id}',data:service.toMap()).then((_){});
  Future<void> deleteService(String providerId,String serviceId)=>_api.delete('/api/providers/$providerId/services/$serviceId').then((_){});
  Stream<T> _poll<T>(Future<T> Function() load) async* { while (true) { yield await load(); await Future<void>.delayed(const Duration(seconds: 3)); } }
  Stream<List<T>> _pollList<T>(Future<List<T>> Function() load)=>_poll(load);
}
