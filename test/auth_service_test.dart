import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
