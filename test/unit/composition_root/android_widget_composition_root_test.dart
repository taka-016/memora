import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/composition_root/android_widget_composition_root.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_exception.dart';
import 'android_widget_composition_root_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AndroidWidgetCacheStorage>(),
  MockSpec<OfflineDatabase>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'resolved_app_mode': 'offline'});
  });

  test('保存済みオフラインモードでSQLiteの旅程を定期更新と操作へ注入する', () async {
    final database = OfflineDatabase(NativeDatabase.memory());
    await database.initialize();
    await database.insertRow('members', {
      'id': 'member',
      'display_name': '利用者',
    });
    await database.insertRow('groups', {
      'id': 'group',
      'owner_id': 'member',
      'name': '旅行',
    });
    await database.insertRow('trip_entries', {
      'id': 'trip',
      'group_id': 'group',
      'year': 2026,
      'name': '端末内の旅行',
    });
    await database.insertRow('itinerary_items', {
      'id': 'item',
      'trip_id': 'trip',
      'name': '端末内の旅程',
      'start_date_time': DateTime(2026, 9, 12, 10).microsecondsSinceEpoch,
    });
    final storage = MockAndroidWidgetCacheStorage();
    when(storage.getTargetGroupId()).thenAnswer((_) async => 'group');

    await withAndroidWidgetDependencies(
      (refresh, handler) async {
        await refresh.execute(
          groupId: 'group',
          updateWidgetAfterRefresh: false,
        );
        await handler.handle(Uri.parse('memora://recent'));
        await refresh.executeForSelectedGroup();
      },
      createOfflineDatabase: () => database,
      cacheStorage: storage,
    );

    final caches = verify(storage.saveItineraryCache(captureAny)).captured
        .cast<AndroidWidgetItineraryCacheDto>();
    expect(caches, hasLength(3));
    for (final cache in caches) {
      expect(cache.itineraryDates.single.tripName, '端末内の旅行');
      expect(cache.itineraryDates.single.itineraryItems.single.name, '端末内の旅程');
    }
  });

  for (final failInitialization in [false, true]) {
    test('${failInitialization ? '初期化' : '更新'}失敗時もDBの終了完了を待つ', () async {
      final database = MockOfflineDatabase();
      final closing = Completer<void>();
      final release = Completer<void>();
      final failure = TestException('処理失敗');
      if (failInitialization) {
        when(database.initialize()).thenThrow(failure);
      }
      when(database.close()).thenAnswer((_) {
        closing.complete();
        return release.future;
      });
      var completed = false;
      final operation = withAndroidWidgetDependencies((refresh, handler) async {
        throw failure;
      }, createOfflineDatabase: () => database);
      final assertion = expectLater(operation, throwsA(same(failure)));
      final tracked = assertion.whenComplete(() => completed = true);
      await closing.future;
      expect(completed, isFalse);
      release.complete();
      await tracked;
      verify(database.close()).called(1);
    });
  }

  test('モード未保存ならFirebaseやDBを初期化せず更新を拒否する', () async {
    SharedPreferences.setMockInitialValues({});
    var opened = false;
    await expectLater(
      withAndroidWidgetDependencies(
        (refresh, handler) async {
          fail('更新処理を実行しない');
        },
        createOfflineDatabase: () {
          opened = true;
          return MockOfflineDatabase();
        },
      ),
      throwsStateError,
    );
    expect(opened, isFalse);
  });
}
