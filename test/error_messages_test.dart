import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_service_app/core/utils/error_messages.dart';

void main() {
  test('422 errors are friendly and do not expose backend validation details',
      () {
    final request = RequestOptions(path: '/api/providers');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 422,
        data: {
          'detail': [
            {
              'type': 'float_parsing',
              'loc': ['query', 'near_lat'],
              'msg': 'Input should be a valid number',
              'input': '',
            },
          ],
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final message = friendlyErrorMessage(error);
    expect(message, contains('missing or invalid'));
    expect(message, isNot(contains('near_lat')));
    expect(message, isNot(contains('DioException')));
  });
}
