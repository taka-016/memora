import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/usecases/android_widget/get_calendar_widget_selection_usecase.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_calendar_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';
import 'package:memora/composition_root/providers/calendar_widget_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

import '../../../helpers/test_exception.dart';
import 'calendar_widget_providers_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetCalendarWidgetSelectionUsecase>(),
  MockSpec<GetAndroidWidgetCalendarCacheUsecase>(),
  MockSpec<HomeWidgetCalendarCacheStorage>(),
])
void main() {
  late MockGetCalendarWidgetSelectionUsecase selection;
  late MockGetAndroidWidgetCalendarCacheUsecase cache;
  late MockHomeWidgetCalendarCacheStorage storage;
  late ProviderContainer container;
  late CalendarWidgetSelection current;
  late Future<Set<AndroidWidgetKind>> Function() widgetKinds;
  final month = DateTime(2026, 11);
  setUp(() {
    selection = MockGetCalendarWidgetSelectionUsecase();
    cache = MockGetAndroidWidgetCalendarCacheUsecase();
    storage = MockHomeWidgetCalendarCacheStorage();
    widgetKinds = () async => {AndroidWidgetKind.calendar};
    current = CalendarWidgetSelection(
      mode: AppMode.online,
      ownerId: 'online:a',
      visibleGroups: const [
        GroupDto(id: 'a', ownerId: 'a', name: '家族', members: []),
      ],
    );
    when(selection.execute()).thenAnswer((_) async => current);
    when(selection.loadCurrentScope())
        .thenAnswer((_) async => current.cacheScope);
    when(storage.synchronize(any)).thenAnswer(
      (call) async =>
          (call.positionalArguments[0] as Future<void> Function())(),
    );
    when(storage.loadScope()).thenAnswer((_) async => current.cacheScope);
    when(storage.setScopeIfCurrent(any, any)).thenAnswer((call) async {
      if (await storage.loadScope() != call.positionalArguments[0]) {
        return false;
      }
      await storage.setScope(call.positionalArguments[1] as String?);
      return true;
    });
    when(storage.refresh(any, any, any)).thenAnswer(
      (call) async =>
          (call.positionalArguments[2] as Future<void> Function())(),
    );
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer(
      (_) async => {
        'cacheScope': current.cacheScope,
        'month': '2026-11-01',
        'months': <String, Object?>{},
      },
    );
    container = ProviderContainer(
      overrides: [
        calendarWidgetSupportedProvider.overrideWithValue(true),
        loadInstalledAndroidWidgetKindsProvider.overrideWithValue(
          () => widgetKinds(),
        ),
        getCalendarWidgetSelectionUsecaseProvider.overrideWithValue(selection),
        getAndroidWidgetCalendarCacheUsecaseProvider.overrideWithValue(cache),
        calendarWidgetCacheStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
  });
  test('1回の更新で表示用のグループ・メンバー情報を一度だけ取得する', () async {
    await container.read(refreshCalendarWidgetProvider)(month);
    verifyInOrder([
      selection.execute(),
      cache.execute(current.visibleGroups, month, ownerId: current.ownerId),
      selection.loadCurrentScope(),
    ]);
    verifyNoMoreInteractions(selection);
    verify(storage.save(any, retainMonthsWithin: null)).called(1);
  });
  test('予定保存後は別のウィジェットで公開済みの月も保存前の表示に戻さない', () async {
    final september = DateTime(2026, 9);
    when(storage.loadSelectedDate()).thenAnswer((_) async => month);
    when(storage.loadPublishedMonths(current.cacheScope))
        .thenAnswer((_) async => [september]);
    when(
      cache.execute(
        current.visibleGroups,
        month,
        ownerId: current.ownerId,
        publishedMonths: anyNamed('publishedMonths'),
      ),
    ).thenAnswer(
      (call) async => {
        'cacheScope': current.cacheScope,
        'month': '2026-11-01',
        'months': {
          '2026-09-01': {'days': []},
          '2026-11-01': {'days': []},
        },
      },
    );

    await container.read(refreshCalendarWidgetProvider)(
      null,
      afterMutation: true,
    );

    final arguments = verify(
      cache.execute(
        current.visibleGroups,
        month,
        ownerId: current.ownerId,
        publishedMonths: captureAnyNamed('publishedMonths'),
      ),
    ).captured;
    expect(arguments.single, [september]);
    final saved =
        verify(storage.save(captureAny, retainMonthsWithin: null))
                .captured
                .single
            as Map<String, Object?>;
    expect((saved['months'] as Map).keys, ['2026-09-01', '2026-11-01']);
    verify(selection.execute()).called(1);
    verify(selection.loadCurrentScope()).called(1);
  });

  test('バックアップ復元後は取得済み月を引き継がない', () async {
    await container.read(refreshCalendarWidgetProvider)(
      null,
      afterRestore: true,
    );
    verify(storage.save(any, retainMonthsWithin: 0)).called(1);
  });
  test('復元後の取得中に通常更新が入っても復元前の月を破棄する', () async {
    final started = Completer<void>();
    final done = Completer<Map<String, Object?>?>();
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer((_) {
      started.complete();
      return done.future;
    });
    final refresh = container.read(refreshCalendarWidgetProvider);
    final restored = refresh(null, afterRestore: true);
    await started.future;
    final nextRequest = Completer<void>();
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer(
      (_) async => {'cacheScope': current.cacheScope, 'month': '2026-11-01'},
    );
    widgetKinds = () async {
      nextRequest.complete();
      return {AndroidWidgetKind.calendar};
    };
    final latest = refresh(null);
    await nextRequest.future;
    await Future<void>.value();
    done.complete({'cacheScope': current.cacheScope, 'month': '2026-11-01'});
    await Future.wait([restored, latest]);
    verify(storage.save(any, retainMonthsWithin: 0)).called(1);
  });
  test('取得中に所属が変われば旧スコープのキャッシュを公開しない', () async {
    final started = Completer<void>();
    final done = Completer<Map<String, Object?>?>();
    final old = current;
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer((_) {
      started.complete();
      return done.future;
    });
    final refresh = container.read(refreshCalendarWidgetProvider)(month);
    await started.future;
    clearInteractions(storage);
    current = CalendarWidgetSelection(
      mode: AppMode.online,
      ownerId: old.ownerId,
      visibleGroups: const [],
    );
    when(storage.loadScope()).thenAnswer((_) async => old.cacheScope);
    done.complete({
      'cacheScope': old.cacheScope,
      'month': '2026-11-01',
      'months': <String, Object?>{},
    });
    await refresh;
    verify(storage.setScope(current.cacheScope)).called(1);
    verifyNever(
      storage.save(any, retainMonthsWithin: anyNamed('retainMonthsWithin')),
    );
  });
  test('取得に失敗しても次の要求を直列に実行し再公開できる', () async {
    when(cache.execute(any, any, ownerId: anyNamed('ownerId')))
        .thenThrow(TestException('取得失敗'));
    await expectLater(
      container.read(refreshCalendarWidgetProvider)(month),
      throwsA(isA<TestException>()),
    );
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer(
      (_) async => {
        'cacheScope': current.cacheScope,
        'month': '2026-11-01',
        'months': <String, Object?>{},
      },
    );
    await container.read(refreshCalendarWidgetProvider)(month);
    verify(storage.save(any, retainMonthsWithin: null)).called(1);
    verify(storage.setScope(current.cacheScope)).called(2);
    verifyNever(storage.setScope(null));
  });
}
