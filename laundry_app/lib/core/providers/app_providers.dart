import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/provider_repository.dart';
import '../repositories/review_repository.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/sms_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authServiceProvider = Provider<AuthService>((ref) => AuthService(api: ref.watch(apiClientProvider)));
final smsServiceProvider = Provider<SmsService>((ref) => SmsService(api: ref.watch(apiClientProvider)));
final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService(api: ref.watch(apiClientProvider)));
final providerRepositoryProvider = Provider<ProviderRepository>((ref) => ProviderRepository(api: ref.watch(apiClientProvider)));
final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository(api: ref.watch(apiClientProvider)));
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository(api: ref.watch(apiClientProvider)));
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) => ReviewRepository(api: ref.watch(apiClientProvider), providerRepository: ref.watch(providerRepositoryProvider)));

final currentUserProvider = StreamProvider<UserModel?>((ref) => ref.watch(authServiceProvider).authStateChanges());
final customerTabIndexProvider = StateProvider<int>((ref) => 0);
