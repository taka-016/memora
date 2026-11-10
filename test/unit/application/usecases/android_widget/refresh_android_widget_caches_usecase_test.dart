import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';
import 'package:mockito/mockito.dart';

import '../../../composition_root/providers/android_widget_providers_test.mocks.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  for (final installed in <Set<AndroidWidgetKind>>[
    {}, {AndroidWidgetKind.calendar}, {AndroidWidgetKind.itinerary},
    AndroidWidgetKind.values.toSet(),
  ]) {
    for (final requested in <Set<AndroidWidgetKind>>[
      {AndroidWidgetKind.calendar}, {AndroidWidgetKind.itinerary},
      AndroidWidgetKind.values.toSet(),
    ]) {
      test('配置$installedで更新対象$requestedだけを取得する', () async {
        final storage = MockAndroidWidgetCacheStorage();
        when(storage.getTargetGroupId()).thenAnswer((_) async => 'group');
        final fetched = <AndroidWidgetKind>[];
        final usecase = RefreshAndroidWidgetCachesUsecase(
          storage: storage,
          loadInstalledKinds: () async => installed,
          refreshItinerary: (group) async {
            expect(group, 'group');
            fetched.add(AndroidWidgetKind.itinerary);
          },
          refreshCalendar: (group) async {
            expect(group, 'group');
            fetched.add(AndroidWidgetKind.calendar);
          },
        );
        await usecase.execute(kinds: requested);
        expect(fetched.toSet(), installed.intersection(requested));
      });
    }
  }

  test('対象グループ未設定ならデータ取得しない', () async {
    final storage = MockAndroidWidgetCacheStorage();
    final usecase = RefreshAndroidWidgetCachesUsecase(
      storage: storage,
      loadInstalledKinds: () async => AndroidWidgetKind.values.toSet(),
      refreshItinerary: (_) async => fail('旅程を取得しない'),
      refreshCalendar: (_) async => fail('カレンダーを取得しない'),
    );
    await usecase.execute();
  });

  test('旅程取得が失敗してもカレンダーを更新し次の呼び出しで旅程を再試行できる', () async {
    final storage = MockAndroidWidgetCacheStorage();
    when(storage.getTargetGroupId()).thenAnswer((_) async => 'group');
    var attempts = 0;
    var calendarUpdates = 0;
    final usecase = RefreshAndroidWidgetCachesUsecase(
      storage: storage,
      loadInstalledKinds: () async => AndroidWidgetKind.values.toSet(),
      refreshItinerary: (_) async {
        if (++attempts == 1) throw TestException('取得失敗');
      },
      refreshCalendar: (_) async { calendarUpdates++; },
    );
    await expectLater(usecase.execute(), throwsA(isA<TestException>()));
    expect(calendarUpdates, 1);
    await usecase.execute();
    expect(attempts, 2);
    expect(calendarUpdates, 2);
  });
}
