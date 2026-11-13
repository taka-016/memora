import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/application/services/app_availability_source.dart';
import 'package:memora/application/usecases/app_availability/check_app_availability_usecase.dart';

import '../../../../helpers/test_exception.dart';
import 'check_app_availability_usecase_test.mocks.dart';

@GenerateMocks([AppAvailabilitySource])
void main() {
  late MockAppAvailabilitySource source;
  late CheckAppAvailabilityUsecase usecase;
  setUp(() {
    source = MockAppAvailabilitySource();
    usecase = CheckAppAvailabilityUsecase(
      source: source,
      loadBuildNumber: () async => 10,
    );
  });

  for (final entry in [
    (9, false, AppAvailability.available),
    (10, false, AppAvailability.available),
    (11, false, AppAvailability.updateRequired),
    (9, true, AppAvailability.maintenance),
    (11, true, AppAvailability.maintenance),
  ]) {
    test('最低ビルド${entry.$1}・メンテナンス${entry.$2}から${entry.$3.name}を判定する', () async {
      when(source.load()).thenAnswer(
        (_) async => AppAvailabilitySettings(
          minimumBuildNumber: entry.$1,
          isMaintenance: entry.$2,
        ),
      );
      expect(await usecase.execute(), entry.$3);
    });
  }

  test('停止中はバックグラウンド処理を実行せず解除後に再開する', () async {
    var count = 0;
    when(source.load()).thenAnswer(
      (_) async => const AppAvailabilitySettings(
        minimumBuildNumber: 11,
        isMaintenance: false,
      ),
    );
    expect(
      await usecase.runIfAvailable(() async {
        count++;
      }),
      isFalse,
    );
    expect(count, 0);
    when(source.load()).thenAnswer(
      (_) async => const AppAvailabilitySettings(
        minimumBuildNumber: 10,
        isMaintenance: false,
      ),
    );
    expect(
      await usecase.runIfAvailable(() async {
        count++;
      }),
      isTrue,
    );
    expect(count, 1);
  });

  test('設定取得に失敗した場合はバックグラウンド処理を開始しない', () async {
    when(source.load()).thenThrow(TestException('取得失敗'));
    var ran = false;
    await expectLater(
      usecase.runIfAvailable(() async {
        ran = true;
      }),
      throwsA(isA<TestException>()),
    );
    expect(ran, isFalse);
  });

  test('オフライン版は外部設定とビルド番号を取得せず利用できる', () async {
    expect(
      await const CheckAppAvailabilityUsecase.unrestricted().execute(),
      AppAvailability.available,
    );
  });
}
