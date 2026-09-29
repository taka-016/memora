import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/app_mode_resolver.dart';
import 'package:memora/infrastructure/config/app_mode_build_configuration.dart';

void main() {
  group('AppModeBuildConfiguration', () {
    test('onlineはオンラインモードを強制する', () {
      final configuration = AppModeBuildConfiguration.parse('online');

      expect(configuration.requestedValue, 'online');
      expect(configuration.forcedMode, AppMode.online);
    });

    test('offlineはオフラインモードを強制する', () {
      final configuration = AppModeBuildConfiguration.parse('offline');

      expect(configuration.requestedValue, 'offline');
      expect(configuration.forcedMode, AppMode.offline);
    });

    for (final value in ['auto', 'invalid']) {
      test('$valueは設定誤りとして検出する', () {
        expect(
          () => AppModeBuildConfiguration.parse(value),
          throwsA(
            isA<ArgumentError>()
                .having(
                  (error) => error.message,
                  'message',
                  contains('MEMORA_APP_MODE'),
                )
                .having((error) => error.invalidValue, 'invalidValue', value),
          ),
        );
      });
    }

    test('未指定時はonlineとしてビルド情報を読み取る', () {
      const expectedValue = String.fromEnvironment(
        'MEMORA_APP_MODE',
        defaultValue: 'online',
      );

      final configuration = AppModeBuildConfiguration.fromEnvironment();

      expect(configuration.requestedValue, expectedValue);
    });
  });

  group('AppModeResolver', () {
    test('強制モードがあればそのモードに決定する', () {
      const resolver = AppModeResolver();

      expect(resolver.resolve(forcedMode: AppMode.online), AppMode.online);
      expect(resolver.resolve(forcedMode: AppMode.offline), AppMode.offline);
    });

    test('強制モードがなければ現在はオンラインモードに決定する', () {
      const resolver = AppModeResolver();

      expect(resolver.resolve(), AppMode.online);
    });
  });
}
