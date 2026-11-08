import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 422) {
      return 'Some information is missing or invalid. Check your entries and try again.';
    }
    if (statusCode == 401) {
      return 'Your session has expired. Sign in again and retry.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to complete this request.';
    }
    if (statusCode == 404) {
      return 'This information is no longer available. Refresh and try again.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'The service is temporarily unavailable. Please try again shortly.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Could not reach the service. Check your internet connection and try again.';
    }
    final body = error.response?.data;
    if (body is Map && body['detail'] is String) {
      return body['detail'] as String;
    }
    return 'We could not complete that request. Please try again.';
  }

  if (error is String) {
    final message = error.trim();
    if (message.isNotEmpty &&
        !message.startsWith('DioException') &&
        !message.startsWith('Exception:')) {
      return message;
    }
  }
  return 'Something went wrong. Please try again.';
}
