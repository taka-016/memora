import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide OrderBy;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/composition_root/android_widget_composition_root.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/infrastructure/config/app_mode_build_configuration.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_exception.dart';
import 'android_widget_snapshot_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AndroidWidgetCacheStorage>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final forcedMode = AppModeBuildConfiguration.fromEnvironment().forcedMode;
  late Directory directory;
  late OfflineDatabase writer;
  late _InterceptingDatabase reader;
  late MockAndroidWidgetCacheStorage storage;
  late bool previousWarning;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'resolved_app_mode': 'offline'});
    directory = await Directory.systemTemp.createTemp(
      'memora-widget-snapshot-',
    );
    previousWarning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    writer = OfflineDatabase.device(directory: () async => directory);
    await writer.initialize();
    await writer.insertRow('members', {'id': 'member', 'display_name': '利用者'});
    await writer.insertRow('groups', {
      'id': 'group',
      'owner_id': 'member',
      'name': '旅行',
    });
    await writer.insertRow('trip_entries', {
      'id': 'trip',
      'group_id': 'group',
      'year': 2026,
      'name': '変更前の旅行',
    });
    await writer.insertRow('itinerary_items', {
      'id': 'item',
      'trip_id': 'trip',
      'name': '変更前の旅程',
      'start_date_time': DateTime(2026, 9, 12, 10).microsecondsSinceEpoch,
    });
    reader = _InterceptingDatabase(
      NativeDatabase.createInBackground(
        File('${directory.path}/memora.sqlite'),
      ),
    );
    await reader.initialize();
    storage = MockAndroidWidgetCacheStorage();
    when(storage.getTargetGroupId()).thenAnswer((_) async => 'group');
  });

  tearDown(() async {
    await reader.close();
    await writer.close();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarning;
    await directory.delete(recursive: true);
  });

  Future<void> updateTrip() async {
    await writer.transaction(() async {
      await writer.updateRow('trip_entries', 'trip', {'name': '変更後の旅行'});
      await writer.updateRow('itinerary_items', 'item', {'name': '変更後の旅程'});
    });
  }

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      appModeProvider.overrideWithValue(AppMode.offline),
      offlineDatabaseProvider.overrideWithValue(reader),
      appClockProvider.overrideWithValue(FixedAppClock(DateTime(2026, 9, 12))),
      androidWidgetCacheStorageProvider.overrideWithValue(storage),
    ],
  );

  for (final background in [true, false]) {
    test(
      '${background ? '定期更新' : '保存後更新'}中の別接続の保存で旅行と旅程の取得時点を混在させない',
      skip: background && forcedMode == AppMode.online,
      () async {
        reader.afterTripsRead = updateTrip;
        Future<void> verifyRefresh(
          RefreshAndroidWidgetItineraryCacheUsecase refresh,
        ) async {
          await refresh.executeForSelectedGroup();
          await refresh.executeForSelectedGroup();
          final caches = verify(storage.saveItineraryCache(captureAny)).captured
              .cast<AndroidWidgetItineraryCacheDto>();
          expect(caches, hasLength(2));
          expect(caches[0].itineraryDates.single.tripName, '変更前の旅行');
          expect(
            caches[0].itineraryDates.single.itineraryItems.single.name,
            '変更前の旅程',
          );
          expect(caches[1].itineraryDates.single.tripName, '変更後の旅行');
          expect(
            caches[1].itineraryDates.single.itineraryItems.single.name,
            '変更後の旅程',
          );
        }

        if (background) {
          await withAndroidWidgetDependencies(
            (refresh, handler) async => verifyRefresh(refresh),
            createOfflineDatabase: () => reader,
            cacheStorage: storage,
          );
        } else {
          final container = createContainer();
          try {
            await verifyRefresh(
              container.read(refreshAndroidWidgetItineraryCacheUsecaseProvider),
            );
          } finally {
            container.dispose();
          }
        }
      },
    );
  }

  test('同じ接続で更新が重なっても読み取りトランザクションを混在させない', () async {
    final readStarted = Completer<void>();
    final releaseRead = Completer<void>();
    reader.afterTripsRead = () async {
      readStarted.complete();
      await releaseRead.future;
    };
    final container = createContainer();
    try {
      final refresh = container.read(
        refreshAndroidWidgetItineraryCacheUsecaseProvider,
      );
      final first = refresh.executeForSelectedGroup();
      await readStarted.future;
      final second = refresh.executeForSelectedGroup();
      final completed = expectLater(Future.wait([first, second]), completes);
      try {
        await updateTrip();
      } finally {
        releaseRead.complete();
      }
      await completed;
      final caches = verify(storage.saveItineraryCache(captureAny)).captured
          .cast<AndroidWidgetItineraryCacheDto>();
      expect(caches, hasLength(2));
      for (final cache in caches) {
        final date = cache.itineraryDates.single;
        expect(
          date.itineraryItems.single.name,
          date.tripName == '変更前の旅行' ? '変更前の旅程' : '変更後の旅程',
        );
      }
    } finally {
      container.dispose();
    }
  });

  test('取得失敗後もキャッシュを維持しトランザクションを終了して再取得できる', () async {
    final failure = TestException('旅程取得前に失敗');
    reader.afterTripsRead = () async => throw failure;
    final container = createContainer();
    try {
      final refresh = container.read(
        refreshAndroidWidgetItineraryCacheUsecaseProvider,
      );
      await expectLater(
        refresh.executeForSelectedGroup(),
        throwsA(same(failure)),
      );
      verifyNever(storage.saveItineraryCache(any));
      await updateTrip();
      await refresh.executeForSelectedGroup();
      final cache =
          verify(storage.saveItineraryCache(captureAny)).captured.single
              as AndroidWidgetItineraryCacheDto;
      expect(cache.itineraryDates.single.tripName, '変更後の旅行');
      expect(cache.itineraryDates.single.itineraryItems.single.name, '変更後の旅程');
    } finally {
      container.dispose();
    }
  });
}

class _InterceptingDatabase extends OfflineDatabase {
  _InterceptingDatabase(super.executor);

  Future<void> Function()? afterTripsRead;

  @override
  Future<List<Map<String, Object?>>> rows(
    String table, {
    String? where,
    List<Object> args = const [],
    List<OrderBy>? orderBy,
  }) async {
    final result = await super.rows(
      table,
      where: where,
      args: args,
      orderBy: orderBy,
    );
    if (table == 'trip_entries') {
      final action = afterTripsRead;
      afterTripsRead = null;
      await action?.call();
    }
    return result;
  }
}
