import 'package:flutter_riverpod/misc.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/app_clock_provider.dart';
import 'package:memora/infrastructure/time/ntp_synchronized_app_clock.dart';
import 'package:memora/infrastructure/time/system_app_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/current_location_service_factory.dart';
import 'package:memora/infrastructure/factories/location_search_service_factory.dart';
import 'package:memora/infrastructure/factories/nearby_location_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/transaction_factory.dart';
import 'package:memora/infrastructure/factories/app_services_factory.dart';
import 'package:memora/core/models/coordinate.dart';

void main() {
  test('ビルド指定の判定結果がComposition Rootと時刻Providerへ接続される', () {
    const requested = String.fromEnvironment(
      'MEMORA_APP_MODE',
      defaultValue: 'auto',
    );
    final root = AppCompositionRoot.fromBuildConfiguration();
    final container = root.createContainer();
    addTearDown(container.dispose);
    final expected = requested == 'offline' ? AppMode.offline : AppMode.online;
    expect(container.read(appModeProvider), expected);
    expect(container.read(appClockProvider), same(root.services.clock));
    expect(
      root.services.clock,
      expected == AppMode.offline
          ? isA<SystemAppClock>()
          : isA<NtpSynchronizedAppClock>(),
    );
  });

  test('オフライン初期化と時刻同期は外部SDKを呼び出さない', () async {
    final services = AppServicesFactory.create(AppMode.offline);
    await services.initialize();
    await services.clock.sync();
    expect(services.clock.now(), isA<DateTime>());
  });

  test('オフラインの機能と利用不可理由を共通モデルから取得できる', () {
    final capabilities = AppCapabilities.forMode(AppMode.offline);
    for (final feature in [
      AppFeature.authentication,
      AppFeature.maps,
      AppFeature.locationSearch,
      AppFeature.currentLocation,
      AppFeature.sharing,
      AppFeature.invitations,
    ]) {
      expect(capabilities.availability(feature).isAvailable, isFalse);
      expect(capabilities.availability(feature).reason, isNotEmpty);
    }
    final online = AppCapabilities.forMode(AppMode.online);
    for (final feature in AppFeature.values) {
      expect(online.availability(feature).isAvailable, isTrue);
    }
  });

  test('オフラインでは全Factoryが外部実装を解決せず共通の利用不可結果を返す', () async {
    final container = ProviderContainer(
      overrides: [appModeProvider.overrideWithValue(AppMode.offline)],
    );
    addTearDown(container.dispose);
    // 依存先のSDKを初期化しない環境で、Factoryの実際の選択を確認する。
    for (final provider in [
      authServiceProvider,
      groupRepositoryProvider,
      memberRepositoryProvider,
      memberEventRepositoryProvider,
      memberInvitationRepositoryProvider,
      groupEventRepositoryProvider,
      tripEntryRepositoryProvider,
      dvcPointContractRepositoryProvider,
      dvcLimitedPointRepositoryProvider,
      dvcPointUsageRepositoryProvider,
      groupQueryServiceProvider,
      groupEventQueryServiceProvider,
      tripEntryQueryServiceProvider,
      mapTripEntryQueryServiceProvider,
      itineraryItemQueryServiceProvider,
      androidWidgetItineraryItemQueryServiceProvider,
      taskQueryServiceProvider,
      locationQueryServiceProvider,
      memberQueryServiceProvider,
      memberEventQueryServiceProvider,
      memberInvitationQueryServiceProvider,
      dvcPointContractQueryServiceProvider,
      dvcLimitedPointQueryServiceProvider,
      dvcPointUsageQueryServiceProvider,
      writeTransactionProvider,
    ]) {
      expect(
        () => container.read(provider),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.exception,
            'exception',
            isA<FeatureUnavailableException>(),
          ),
        ),
      );
    }
    await expectLater(
      container.read(locationSearchServiceProvider).searchByKeyword('東京'),
      throwsA(isA<FeatureUnavailableException>()),
    );
    await expectLater(
      container.read(currentLocationServiceProvider).getCurrentLocation(),
      throwsA(isA<FeatureUnavailableException>()),
    );
    await expectLater(
      container
          .read(nearbyLocationServiceProvider)
          .getLocationName(const Coordinate(latitude: 35, longitude: 139)),
      throwsA(isA<FeatureUnavailableException>()),
    );
  });
}
