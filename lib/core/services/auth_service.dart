import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_enums.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  AuthService({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _user;

  UserModel? get currentUser => _user;
  Stream<UserModel?> authStateChanges() async* {
    if (_user == null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        try {
          _user = await me();
        } catch (_) {
          await logout();
        }
      }
    }
    yield _user;
    yield* _controller.stream;
  }

  Future<UserModel> register(
      {required String name,
      required String email,
      required String password,
      required String phone,
      UserRole role = UserRole.customer}) async {
    final response = await _api.post('/api/auth/register', data: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': phone,
      'role': role.value
    });
    return _saveSession(response.data);
  }

  Future<UserModel> login(
      {required String email, required String password}) async {
    final response = await _api.post('/api/auth/login',
        data: {'email': email.trim(), 'password': password});
    return _saveSession(response.data);
  }

  Future<UserModel> me() async {
    final response = await _api.get('/api/auth/me');
    _user = UserModel.fromMap(response.data['uid'].toString(),
        Map<String, dynamic>.from(response.data));
    return _user!;
  }

  Future<UserModel> _saveSession(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token'].toString());
    _user = UserModel.fromMap(data['user']['uid'].toString(),
        Map<String, dynamic>.from(data['user']));
    _controller.add(_user);
    return _user!;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _api.post('/api/auth/forgot-password', data: {'email': email.trim()});
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _user = null;
    _controller.add(null);
  }

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? profileImage,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _api.put('/api/users/me', data: {
      'name': name.trim(),
      'phone': phone.trim(),
      'location': location.trim(),
      'profileImage': profileImage ?? _user?.profileImage ?? '',
      'latitude': latitude,
      'longitude': longitude,
    });
    _user = UserModel.fromMap(response.data['uid'].toString(),
        Map<String, dynamic>.from(response.data));
    _controller.add(_user);
    return _user!;
  }

  String friendlyAuthError(Object error) {
    if (error is DioException) {
      final message =
          error.response?.data is Map ? error.response?.data['detail'] : null;
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty && message.first is Map) {
        final validationMessage = message.first['msg'];
        if (validationMessage is String) return validationMessage;
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        final baseUrl = _api.baseUrl;
        if (baseUrl.contains('10.0.2.2') || baseUrl.contains('localhost')) {
          return 'Cannot reach the laundry server. This APK is still set to a local development address. '
              'It needs to be rebuilt with your deployed API URL.';
        }
        return 'Cannot reach the laundry server at $baseUrl. Check your internet connection and try again.';
      }
      if (error.response?.statusCode != null &&
          error.response!.statusCode! >= 500) {
        return 'The laundry server had a problem while creating your account. Please try again later.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
