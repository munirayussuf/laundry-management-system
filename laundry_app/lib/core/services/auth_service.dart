import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        try { _user = await me(); } catch (_) { await logout(); }
      }
    }
    yield _user;
    yield* _controller.stream;
  }

  Future<UserModel> register({required String name, required String email, required String password, required String phone, UserRole role = UserRole.customer}) async {
    final response = await _api.post('/api/auth/register', data: {'name': name.trim(), 'email': email.trim(), 'password': password, 'phone': phone, 'role': role.value});
    return _saveSession(response.data);
  }

  Future<UserModel> login({required String email, required String password}) async {
    final response = await _api.post('/api/auth/login', data: {'email': email.trim(), 'password': password});
    return _saveSession(response.data);
  }

  Future<UserModel> me() async {
    final response = await _api.get('/api/auth/me');
    _user = UserModel.fromMap(response.data['uid'].toString(), Map<String, dynamic>.from(response.data));
    return _user!;
  }

  Future<UserModel> _saveSession(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token'].toString());
    _user = UserModel.fromMap(data['user']['uid'].toString(), Map<String, dynamic>.from(data['user']));
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

  Future<UserModel> updateProfile({required String name, required String phone, required String location}) async {
    final response = await _api.put('/api/users/me', data: {'name': name.trim(), 'phone': phone.trim(), 'location': location.trim()});
    _user = UserModel.fromMap(response.data['uid'].toString(), Map<String, dynamic>.from(response.data));
    _controller.add(_user);
    return _user!;
  }

  String friendlyAuthError(Object error) {
    if (error is DioException) {
      final message = error.response?.data is Map ? error.response?.data['detail'] : null;
      if (message is String && message.isNotEmpty) return message;
      if (error.type == DioExceptionType.connectionError) return 'No internet connection. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
