import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memora/infrastructure/config/route_info_api_type.dart';
import 'package:memora/infrastructure/config/route_info_api_type_provider.dart';
import 'package:memora/infrastructure/factories/route_info_service_factory.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_info_service.dart';

void main() {
  group('RouteInfoServiceFactory', () {
    test('googleRoutes指定時はGoogleRoutesApiRouteInfoServiceを返す', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(routeInfoServiceProvider);

      expect(service, isA<GoogleRoutesApiRouteInfoService>());
    });

    test('Provider破棄時にHTTPクライアントも破棄される', () {
      final client = _TrackingClient();
      final container = ProviderContainer(
        overrides: [
          routeInfoHttpClientProvider.overrideWith((ref) {
            ref.onDispose(client.close);
            return client;
          }),
        ],
      );

      container.read(routeInfoServiceProvider);
      container.dispose();

      expect(client.isClosed, isTrue);
    });

    test('local指定時は未実装エラーを投げる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(routeInfoApiTypeProvider.notifier).state =
          RouteInfoApiType.local;

      expect(
        () => container.read(routeInfoServiceProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}

class _TrackingClient extends http.BaseClient {
  bool isClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Future.error(UnimplementedError());
  }

  @override
  void close() {
    isClosed = true;
    super.close();
  }
}
