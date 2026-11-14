import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/usecases/android_widget/get_calendar_widget_selection_usecase.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_calendar_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';
import 'package:memora/composition_root/providers/calendar_widget_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';
import '../../../helpers/test_exception.dart';
import 'calendar_widget_providers_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GetCalendarWidgetSelectionUsecase>(), MockSpec<GetAndroidWidgetCalendarCacheUsecase>(), MockSpec<HomeWidgetCalendarCacheStorage>()])
void main() {
  late MockGetCalendarWidgetSelectionUsecase selection;
  late MockGetAndroidWidgetCalendarCacheUsecase cache;
  late MockHomeWidgetCalendarCacheStorage storage;
  late ProviderContainer container;
  late CalendarWidgetSelection current;
  final month = DateTime(2026, 11);
  setUp(() {
    selection = MockGetCalendarWidgetSelectionUsecase(); cache = MockGetAndroidWidgetCalendarCacheUsecase(); storage = MockHomeWidgetCalendarCacheStorage();
    current = CalendarWidgetSelection(mode: AppMode.online, ownerId: 'online:a', visibleGroupIds: {'a'});
    when(selection.execute()).thenAnswer((_) async => current);
    when(storage.synchronize(any)).thenAnswer((call) async => (call.positionalArguments[0] as Future<void> Function())());
    when(storage.loadScope()).thenAnswer((_) async => current.cacheScope);
    when(storage.setScopeIfCurrent(any, any)).thenAnswer((call) async {
      if (await storage.loadScope() != call.positionalArguments[0]) return false;
      await storage.setScope(call.positionalArguments[1] as String?);
      return true;
    });
    when(storage.refresh(any, any, any)).thenAnswer((call) async => (call.positionalArguments[2] as Future<void> Function())());
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer((_) async => {'cacheScope': current.cacheScope, 'month': '2026-11-01', 'months': <String,Object?>{}});
    container = ProviderContainer(overrides: [
      calendarWidgetSupportedProvider.overrideWithValue(true),
      loadInstalledAndroidWidgetKindsProvider.overrideWithValue(() async => {AndroidWidgetKind.calendar}),
      getCalendarWidgetSelectionUsecaseProvider.overrideWithValue(selection),
      getAndroidWidgetCalendarCacheUsecaseProvider.overrideWithValue(cache),
      calendarWidgetCacheStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  });
  test('取得中に他の処理が表示選択を変更したら旧スコープを公開しない', () async {
    final started = Completer<void>(); final done = Completer<Map<String,Object?>?>();
    final old = current;
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer((_) { started.complete(); return done.future; });
    final refresh = container.read(refreshCalendarWidgetProvider)(month);
    await started.future;
    clearInteractions(storage);
    current = CalendarWidgetSelection(mode: AppMode.online, ownerId: 'online:b', visibleGroupIds: {});
    done.complete({'cacheScope': old.cacheScope, 'month': '2026-11-01', 'months': <String,Object?>{}});
    await refresh;
    verifyNever(storage.setScope(old.cacheScope));
    verifyNever(storage.save(any, merge: anyNamed('merge')));
  });
  test('取得に失敗しても次の要求を直列に実行し再公開できる', () async {
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenThrow(TestException('取得失敗'));
    await expectLater(container.read(refreshCalendarWidgetProvider)(month), throwsA(isA<TestException>()));
    when(cache.execute(any, any, ownerId: anyNamed('ownerId'))).thenAnswer((_) async => {'cacheScope': current.cacheScope, 'month': '2026-11-01', 'months': <String,Object?>{}});
    await container.read(refreshCalendarWidgetProvider)(month);
    verify(storage.save(any, merge: true)).called(1);
    verify(storage.setScope(current.cacheScope)).called(2);
    verifyNever(storage.setScope(null));
  });
}
