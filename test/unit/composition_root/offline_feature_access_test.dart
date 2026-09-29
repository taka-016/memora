import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/composition_root/providers/trip_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';

import '../../helpers/test_exception.dart';

void main() {
  test('UI以外からのオンライン機能解決も共通の利用不可結果を返す', () {
    final container = ProviderContainer(
      overrides: [appModeProvider.overrideWithValue(AppMode.offline)],
    );
    addTearDown(container.dispose);
    for (final (provider, feature) in [
      (acceptInvitationUseCaseProvider, AppFeature.invitations),
      (createOrUpdateMemberInvitationUsecaseProvider, AppFeature.invitations),
      (getLocationsByGroupIdUsecaseProvider, AppFeature.maps),
      (getMapTripEntriesUsecaseProvider, AppFeature.maps),
    ]) {
      expect(
        () => container.read(provider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            '利用不可結果',
            isA<FeatureUnavailableException>().having(
              (e) => e.feature,
              '機能',
              feature,
            ),
          ),
        ),
      );
    }
  });

  test('オフラインで認証Notifierを参照しても認証サービスを購読しない', () {
    var resolutions = 0;
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.offline),
        authServiceProvider.overrideWith((ref) {
          resolutions++;
          throw TestException('認証は利用しない');
        }),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(authNotifierProvider).isAuthenticated, false);
    expect(resolutions, 0);
  });
}
