import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_service_app/core/repositories/provider_repository.dart';
import 'package:laundry_service_app/core/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('provider search sends only named, valid GET query parameters',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final repository = ProviderRepository(api: ApiClient(dio: dio));
    final firstResult = Completer<void>();
    final subscription = repository.searchProviders('  Luxe  ').listen((_) {
      if (!firstResult.isCompleted) firstResult.complete();
    });

    await firstResult.future.timeout(const Duration(seconds: 2));
    await subscription.cancel();

    final request = adapter.request!;
    expect(request.method, 'GET');
    expect(request.uri.path, '/api/providers');
    expect(request.uri.queryParameters, {
      'search': 'Luxe',
      'only_active': 'true',
    });
    expect(request.data, isNull);
    expect(request.headers['Content-Type'], isNull);
    expect(request.uri.queryParameters, isNot(contains('near_lat')));
    expect(request.uri.queryParameters, isNot(contains('near_lon')));
  });

  test('provider search includes both coordinates only when both are valid',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final repository = ProviderRepository(api: ApiClient(dio: dio));
    final firstResult = Completer<void>();
    final subscription = repository
        .searchProviders(
      '',
      nearLatitude: -1.2921,
      nearLongitude: 36.8219,
    )
        .listen((_) {
      if (!firstResult.isCompleted) firstResult.complete();
    });

    await firstResult.future.timeout(const Duration(seconds: 2));
    await subscription.cancel();

    final request = adapter.request!;
    expect(request.uri.queryParameters, {
      'only_active': 'true',
      'near_lat': '-1.2921',
      'near_lon': '36.8219',
    });
  });

  test('invalid or incomplete coordinates are omitted from provider search',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final repository = ProviderRepository(api: ApiClient(dio: dio));
    final firstResult = Completer<void>();
    final subscription = repository
        .searchProviders(
      'Laundry',
      nearLatitude: double.nan,
      nearLongitude: 36.8219,
    )
        .listen((_) {
      if (!firstResult.isCompleted) firstResult.complete();
    });

    await firstResult.future.timeout(const Duration(seconds: 2));
    await subscription.cancel();

    expect(adapter.request!.uri.queryParameters, {
      'search': 'Laundry',
      'only_active': 'true',
    });
  });
}
