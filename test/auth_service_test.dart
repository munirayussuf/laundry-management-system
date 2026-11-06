import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_service_app/core/services/api_client.dart';
import 'package:laundry_service_app/core/services/auth_service.dart';

void main() {
  test('shows the API validation message for registration errors', () {
    final service = AuthService();
    final requestOptions = RequestOptions(path: '/api/auth/register');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 409,
        data: {'detail': 'An account already exists with that email address.'},
      ),
    );

    expect(
      service.friendlyAuthError(error),
      'An account already exists with that email address.',
    );
  });

  test('explains that a local API address cannot be reached from a phone', () {
    final service = AuthService(
      api: ApiClient(baseUrl: 'http://10.0.2.2:8000'),
    );
    final error = DioException(
      requestOptions: RequestOptions(path: '/api/auth/register'),
      type: DioExceptionType.connectionError,
    );

    expect(
      service.friendlyAuthError(error),
      contains('rebuilt with your deployed API URL'),
    );
  });

  test('shows validation errors returned as FastAPI detail arrays', () {
    final service = AuthService();
    final requestOptions = RequestOptions(path: '/api/auth/register');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 422,
        data: {
          'detail': [
            {'msg': 'Enter a valid phone number'}
          ]
        },
      ),
    );

    expect(service.friendlyAuthError(error), 'Enter a valid phone number');
  });
}
