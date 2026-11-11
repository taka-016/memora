import '../../../../helpers/widget_itinerary_day_query_fixture.dart';
import 'package:drift/native.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/queries/group/sqlite_group_query_service.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_repository.dart';

import '../group/get_group_with_members_by_id_usecase_test.mocks.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:mockito/mockito.dart';

import '../../../infrastructure/repositories/calendar/firestore_calendar_repository_test.mocks.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:memora/application/transactions/read_transaction.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('ウィジェット設定と復元後同期の排他', () {
    test('復元後同期の解除後に選んだ対象グループを維持する', () async {
      final storage = _FakeAndroidWidgetCacheStorage();
      final operationLock = _TestOperationLock();
      final syncStarted = Completer<void>();
      final releaseSync = Completer<void>();
      final sync = operationLock.run(() async {
        syncStarted.complete();
        await releaseSync.future;
        await storage.clear();
      });
      await syncStarted.future;
      final select = SelectAndroidWidgetTargetGroupUsecase(
        cacheStorage: storage,
        refreshCaches: _buildRefreshUsecase(
          storage,
          _FakeTripEntryQueryService(),
          _FakeItineraryItemQueryService(),
        ).executeForSelectedGroup,
        updateIntervalStorage: _FakeIntervalStorage(),
        registerPeriodicUpdateTask: (_) async {},
        operationLock: operationLock,
      );
      final selection = select.execute('group-1');
      try {
        await Future<void>.value();
        expect(storage.targetGroupId, isNull);
      } finally {
        releaseSync.complete();
        await Future.wait([sync, selection]);
      }
      expect(storage.targetGroupId, 'group-1');
    });

    test('復元後同期の更新後に解除した対象グループを維持する', () async {
      final storage = _FakeAndroidWidgetCacheStorage();
      final operationLock = _TestOperationLock();
      final syncStarted = Completer<void>();
      final releaseSync = Completer<void>();
      final sync = operationLock.run(() async {
        syncStarted.complete();
        await releaseSync.future;
        await storage.saveTargetGroupId('group-1');
      });
      await syncStarted.future;
      final clear = ClearAndroidWidgetTargetGroupUsecase(
        cacheStorage: storage,
        operationLock: operationLock,
      );
      final clearing = clear.execute();
      try {
        await Future<void>.value();
        expect(storage.targetGroupId, isNull);
      } finally {
        releaseSync.complete();
        await Future.wait([sync, clearing]);
      }
      expect(storage.targetGroupId, isNull);
    });
  });

  group('RefreshAndroidWidgetItineraryCacheUsecase', () {
    test('旅程ウィジェットが未配置なら旅行もグループも取得しない', () async {
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-1';
      final groups = MockGroupQueryService();
      final usecase = RefreshAndroidWidgetItineraryCacheUsecase(
        cacheStorage: storage,
        groupQueryService: groups,
        isWidgetInstalled: () async => false,
        getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
          queryService: WidgetItineraryDayQueryFixture(_FakeTripEntryQueryService()..exception = TestException('取得しない'), _FakeItineraryItemQueryService()),
          clock: FixedAppClock(DateTime(2026, 11, 1)),
        ),
      );
      await usecase.executeForSelectedGroup();
      verifyNever(groups.groupExists(any));
    });

    for (final fails in [false, true]) {
      test('旅程取得${fails ? '失敗' : '成功'}を選択日とともに状態管理へ伝える', () async {
        final storage = _FakeAndroidWidgetCacheStorage()
          ..targetGroupId = 'group-1';
        final trips = _FakeTripEntryQueryService();
        if (fails) trips.exception = TestException('取得失敗');
        final trace = <String>[];
        final usecase = _buildRefreshUsecase(
          storage,
          trips,
          _FakeItineraryItemQueryService(),
          trackLoading: (groupId, selected, action, updateWidget) async {
            expect(groupId, 'group-1');
            expect(selected, 'trip_2026-11-08');
            expect(updateWidget, isTrue);
            trace.add('loading');
            try {
              await action();
              trace.add('complete');
            } catch (_) {
              trace.add('failed');
              rethrow;
            }
          },
        );
        final refresh = usecase.execute(
          groupId: 'group-1',
          selectedItineraryDateId: 'trip_2026-11-08',
        );
        if (fails) {
          await expectLater(refresh, throwsA(isA<TestException>()));
        } else {
          await refresh;
        }
        expect(trace, ['loading', fails ? 'failed' : 'complete']);
      });
    }

    test('移動時も周辺だけを保持し更新失敗時は以前の内容を残す', () async {
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-1';
      final trips = _FakeTripEntryQueryService()
        ..trips = [
          const TripEntryDto(id: 'trip', groupId: 'group-1', year: 2026),
        ];
      final items = _FakeItineraryItemQueryService()
        ..items = [
          for (var day = 24; day <= 31; day++)
            ItineraryItemDto(
              id: 'item-$day',
              tripId: 'trip',
              name: '予定$day',
              startDateTime: DateTime(2026, 5, day, 9),
            ),
        ];
      final usecase = _buildRefreshUsecase(storage, trips, items);
      await usecase.execute(
        groupId: 'group-1',
        selectedItineraryDateId: 'trip_2026-05-24',
      );
      expect(storage.cache!.itineraryDates, hasLength(4));
      await usecase.execute(
        groupId: 'group-1',
        selectedItineraryDateId: 'trip_2026-05-28',
        extendCache: true,
      );
      expect(storage.cache!.itineraryDates, hasLength(6));
      await usecase.execute(
        groupId: 'group-1',
        selectedItineraryDateId: 'trip_2026-05-28',
      );
      expect(storage.cache!.itineraryDates.map((date) => date.id), [
        for (var day = 27; day <= 31; day++) 'trip_2026-05-$day',
      ]);
      expect(storage.targetGroupId, 'group-1');
      expect(storage.selectedItineraryDateId, 'trip_2026-05-28');
      final previous = storage.cache;
      trips.exception = TestException('通信失敗');
      await expectLater(
        usecase.executeForSelectedGroup(),
        throwsA(isA<TestException>()),
      );
      expect(storage.cache, same(previous));
      expect(storage.targetGroupId, 'group-1');
      expect(storage.selectedItineraryDateId, 'trip_2026-05-28');
    });

    test('オフラインでグループを退避した後は残した旅行があってもキャッシュを解除する', () async {
      final db = OfflineDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.insertRow('groups', {
        'id': 'group-1',
        'owner_id': 'owner',
        'name': '家族',
      });
      await db.insertRow('trip_entries', {
        'id': 'trip',
        'group_id': 'group-1',
        'year': 2026,
      });
      await SqliteGroupRepository(db).deleteGroup('group-1');
      final storage = _FakeAndroidWidgetCacheStorage(
        cache: _cacheWithItinerary(),
      )..targetGroupId = 'group-1';
      final container = ProviderContainer(
        overrides: [
          appModeProvider.overrideWithValue(AppMode.offline),
          androidWidgetReadTransactionProvider.overrideWithValue(db),
          groupQueryServiceProvider.overrideWithValue(
            SqliteGroupQueryService(db),
          ),
          androidWidgetCacheStorageProvider.overrideWithValue(storage),
          getAndroidWidgetItineraryCacheUsecaseProvider.overrideWithValue(
            GetAndroidWidgetItineraryCacheUsecase(
              queryService: WidgetItineraryDayQueryFixture(_FakeTripEntryQueryService(), _FakeItineraryItemQueryService()),
              clock: FixedAppClock(DateTime(2026, 5, 24, 10)),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(refreshAndroidWidgetItineraryCacheUsecaseProvider)
          .execute(groupId: 'group-1');
      expect(storage.cache, isNull);
      expect(storage.targetGroupId, isNull);
      expect(await db.rows('trip_entries'), hasLength(1));
    });

    for (final missing in [true, false]) {
      test(
        missing ? '退避済みグループは対象設定ごと解除する' : 'グループ取得失敗時は既存キャッシュと対象設定を維持する',
        () async {
          final storage = _FakeAndroidWidgetCacheStorage(
            cache: _cacheWithItinerary(),
          )..targetGroupId = 'group-1';
          final firestore = MockFirebaseFirestore();
          final collection = MockCollectionReference();
          final reference = MockDocumentReference();
          final document = MockDocumentSnapshot();
          when(firestore.collection('groups')).thenReturn(collection);
          when(collection.doc('group-1')).thenReturn(reference);
          when(document.exists).thenReturn(false);
          if (missing) {
            when(reference.get()).thenAnswer((_) async => document);
          } else {
            when(reference.get()).thenThrow(TestException('通信失敗'));
          }
          final container = ProviderContainer(
            overrides: [
              firebaseFirestoreProvider.overrideWithValue(firestore),
              androidWidgetCacheStorageProvider.overrideWithValue(storage),
              getAndroidWidgetItineraryCacheUsecaseProvider.overrideWithValue(
                GetAndroidWidgetItineraryCacheUsecase(
                  queryService: WidgetItineraryDayQueryFixture(_FakeTripEntryQueryService(), _FakeItineraryItemQueryService()),
                  clock: FixedAppClock(DateTime(2026, 5, 24, 10)),
                ),
              ),
            ],
          );
          addTearDown(container.dispose);
          final future = container
              .read(refreshAndroidWidgetItineraryCacheUsecaseProvider)
              .execute(groupId: 'group-1');
          if (missing) {
            await future;
            expect(storage.cache, isNull);
            expect(storage.targetGroupId, isNull);
          } else {
            await expectLater(future, throwsA(isA<TestException>()));
            expect(storage.cache, isNotNull);
            expect(storage.targetGroupId, 'group-1');
          }
          expect(storage.updateWidgetCount, 1);
        },
      );
    }

    test('復元後に公開したキャッシュを先行更新で上書きしない', () async {
      final restoredCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage();
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
        readTransaction: _AfterReadTransaction(() {
          storage.cache = restoredCache;
        }),
      );

      await usecase.execute(groupId: 'group-1');

      expect(storage.cache, same(restoredCache));
    });

    for (final targetGroupId in [null, 'group-1']) {
      test('選択グループ$targetGroupIdの旅程削除後に表示を更新する', () async {
        final existingCache = _cacheWithItinerary();
        final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache)
          ..targetGroupId = targetGroupId;
        final usecase = _buildRefreshUsecase(
          storage,
          _FakeTripEntryQueryService(),
          _FakeItineraryItemQueryService(),
        );
        await usecase.executeForSelectedGroup();
        if (targetGroupId == null) {
          expect(storage.cache, same(existingCache));
          expect(storage.updateWidgetCount, 0);
        } else {
          expect(storage.cache?.groupId, targetGroupId);
          expect(storage.cache?.itineraryDates, isEmpty);
          expect(storage.updateWidgetCount, 1);
        }
      });
    }

    test('自動更新の空結果も置換し描画は呼び出し元に任せる', () async {
      final existingCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      await usecase.execute(
        groupId: 'group-1',
        updateWidgetAfterRefresh: false,
      );

      expect(storage.cache?.itineraryDates, isEmpty);
      expect(storage.cache, isNot(same(existingCache)));
      expect(storage.updateWidgetCount, 0);
    });

    test('手動更新で取得結果が空の場合は空キャッシュへ更新する', () async {
      final existingCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      await usecase.execute(groupId: 'group-1');

      expect(storage.cache, isNot(same(existingCache)));
      expect(storage.cache?.itineraryDates, isEmpty);
      expect(storage.updateWidgetCount, 1);
    });

    test('取得失敗時は既存キャッシュを上書きせずウィジェット表示だけ更新する', () async {
      final existingCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        groupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-24',
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: const [],
      );
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..exception = TestException('取得失敗');
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        _FakeItineraryItemQueryService(),
      );

      await expectLater(
        usecase.execute(groupId: 'group-1'),
        throwsA(isA<TestException>()),
      );

      expect(storage.cache, same(existingCache));
      expect(storage.updateWidgetCount, 1);
    });

    test('古い更新の完了後も新しく選択した対象グループとキャッシュを維持する', () async {
      final oldReadStarted = Completer<void>();
      final releaseOldRead = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-a';
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..beforeReturn = (groupId) async {
          if (groupId != 'group-a') return;
          if (!oldReadStarted.isCompleted) oldReadStarted.complete();
          await releaseOldRead.future;
        };
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        _FakeItineraryItemQueryService(),
      );

      final oldRefresh = usecase.executeForSelectedGroup();
      await oldReadStarted.future;
      await storage.clear();
      await storage.saveTargetGroupId('group-b');
      await usecase.executeForSelectedGroup();
      releaseOldRead.complete();
      await oldRefresh;

      expect(storage.targetGroupId, 'group-b');
      expect(storage.cache?.groupId, 'group-b');
    });

    test('公開可否の確認直後に対象が変わった場合は最後に完了したキャッシュを保存する', () async {
      final oldPublishChecked = Completer<void>();
      final releaseOldPublish = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-a'
        ..afterTargetRead = (readCount) async {
          if (readCount != 2) return;
          oldPublishChecked.complete();
          await releaseOldPublish.future;
        };
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      final oldRefresh = usecase.executeForSelectedGroup();
      await oldPublishChecked.future;
      await storage.clear();
      await storage.saveTargetGroupId('group-b');
      await usecase.executeForSelectedGroup();
      releaseOldPublish.complete();
      await oldRefresh;

      expect(storage.targetGroupId, 'group-b');
      expect(storage.cache?.groupId, 'group-a');
    });
  });

  group('MoveAndroidWidgetSelectedItineraryDateUsecase', () {
    test('復元後のキャッシュを先行した日付移動で上書きしない', () async {
      final first = _cacheWithItinerary().itineraryDates.single;
      final oldCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        groupId: 'group-1',
        selectedItineraryDateId: first.id,
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: [
          first,
          AndroidWidgetItineraryDateCacheDto(
            id: 'trip-1_2026-05-25',
            tripId: 'trip-1',
            tripName: '復元前の旅行',
            tripPeriodLabel: '2026/5/24 - 2026/5/25',
            date: DateTime(2026, 5, 25),
            dateLabel: '2026/5/25',
            itineraryItems: const [],
          ),
        ],
      );
      final restoredCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: oldCache);
      final trips = _FakeTripEntryQueryService();
      final items = _FakeItineraryItemQueryService();
      final readTransaction = _AfterReadTransaction(() {
        storage.cache = restoredCache;
      });
      final usecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: storage,
        queryService: WidgetItineraryDayQueryFixture(trips, items),
        refreshCacheUsecase: _buildRefreshUsecase(storage, trips, items),
        readTransaction: readTransaction,
      );

      expect(
        await usecase.execute(AndroidWidgetItineraryDateMoveDirection.next),
        isTrue,
      );

      expect(storage.cache, same(restoredCache));
    });

    test('リモート探索で失敗した場合は失敗を返してウィジェットを更新する', () async {
      final storage = _FakeAndroidWidgetCacheStorage(
        cache: AndroidWidgetItineraryCacheDto(
          version: 1,
          groupId: 'group-1',
          selectedItineraryDateId: 'trip-1_2026-05-24',
          lastUpdatedAt: DateTime(2026, 5, 24, 10),
          itineraryDates: [
            AndroidWidgetItineraryDateCacheDto(
              id: 'trip-1_2026-05-24',
              tripId: 'trip-1',
              tripName: '旅行',
              tripPeriodLabel: '2026/5/24 - 2026/5/25',
              date: DateTime(2026, 5, 24),
              dateLabel: '2026/5/24',
              itineraryItems: [],
            ),
          ],
        ),
      );
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..exception = TestException('取得失敗');
      final itineraryItemQueryService = _FakeItineraryItemQueryService();
      final usecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: storage,
        queryService: WidgetItineraryDayQueryFixture(tripEntryQueryService, itineraryItemQueryService),
        refreshCacheUsecase: _buildRefreshUsecase(
          storage,
          tripEntryQueryService,
          itineraryItemQueryService,
        ),
      );

      final succeeded = await usecase.execute(
        AndroidWidgetItineraryDateMoveDirection.next,
      );

      expect(succeeded, isFalse);
      expect(storage.errorMessage, isNull);
      expect(storage.updateWidgetCount, 1);
    });
  });
}

class _TestOperationLock implements OfflineBackupRestoreOperationLock {
  Future<void> _previous = Future<void>.value();

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    final previous = _previous;
    final completed = Completer<void>();
    _previous = completed.future;
    await previous;
    try {
      return await action();
    } finally {
      completed.complete();
    }
  }
}

class _FakeIntervalStorage implements AndroidWidgetUpdateIntervalStorage {
  @override
  Future<AndroidWidgetUpdateInterval> load() async =>
      AndroidWidgetUpdateInterval.every24Hours;

  @override
  Future<void> save(AndroidWidgetUpdateInterval interval) async {}
}

AndroidWidgetItineraryCacheDto _cacheWithItinerary() {
  return AndroidWidgetItineraryCacheDto(
    version: 1,
    groupId: 'group-1',
    selectedItineraryDateId: 'trip-1_2026-05-24',
    lastUpdatedAt: DateTime(2026, 5, 24, 10),
    itineraryDates: [
      AndroidWidgetItineraryDateCacheDto(
        id: 'trip-1_2026-05-24',
        tripId: 'trip-1',
        tripName: '旅行',
        tripPeriodLabel: '2026/5/24 - 2026/5/25',
        date: DateTime(2026, 5, 24),
        dateLabel: '2026/5/24',
        itineraryItems: const [],
      ),
    ],
  );
}

RefreshAndroidWidgetItineraryCacheUsecase _buildRefreshUsecase(
  AndroidWidgetCacheStorage storage,
  TripEntryQueryService tripEntryQueryService,
  ItineraryItemQueryService itineraryItemQueryService, {
  ReadTransaction? readTransaction,
  Future<bool> Function()? isWidgetInstalled,
  TrackAndroidWidgetItineraryLoading? trackLoading,
}) {
  final groups = MockGroupQueryService();
  when(groups.groupExists(any)).thenAnswer((_) async => true);
  return RefreshAndroidWidgetItineraryCacheUsecase(
    groupQueryService: groups,
    cacheStorage: storage,
    readTransaction: readTransaction,
    isWidgetInstalled: isWidgetInstalled,
    trackLoading: trackLoading,
    getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
      queryService: WidgetItineraryDayQueryFixture(tripEntryQueryService, itineraryItemQueryService),
      clock: FixedAppClock(DateTime(2026, 5, 24, 10)),
    ),
  );
}

class _AfterReadTransaction implements ReadTransaction {
  _AfterReadTransaction(this.afterRead);

  final void Function() afterRead;

  @override
  Future<T> execute<T>(Future<T> Function() action) async {
    final result = await action();
    afterRead();
    return result;
  }
}

class _FakeAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  _FakeAndroidWidgetCacheStorage({this.cache});

  AndroidWidgetItineraryCacheDto? cache;
  String? targetGroupId;
  String? selectedItineraryDateId;
  String? errorMessage;
  int updateWidgetCount = 0;
  int targetReadCount = 0;
  Future<void> Function(int readCount)? afterTargetRead;

  @override
  Future<void> clear() async {
    cache = null;
    targetGroupId = null;
    selectedItineraryDateId = null;
    errorMessage = null;
  }

  @override
  Future<void> clearTargetGroupId() async {
    targetGroupId = null;
  }

  @override
  Future<String?> getSelectedItineraryDateId() async {
    return selectedItineraryDateId;
  }

  @override
  Future<String?> getTargetGroupId() async {
    final result = targetGroupId;
    await afterTargetRead?.call(++targetReadCount);
    return result;
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    return cache;
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {
    this.cache = cache;
    selectedItineraryDateId = cache.selectedItineraryDateId;
  }

  @override
  Future<void> saveTargetGroupId(String groupId) async {
    targetGroupId = groupId;
  }

  @override
  Future<void> updateWidget() async {
    updateWidgetCount += 1;
  }
}

class _FakeTripEntryQueryService implements TripEntryQueryService {
  List<TripEntryDto> trips = [];
  Object? exception;
  Future<void> Function(String groupId)? beforeReturn;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async {
    return null;
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    await beforeReturn?.call(groupId);
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    return trips;
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    return [];
  }
}

class _FakeItineraryItemQueryService implements ItineraryItemQueryService {
  List<ItineraryItemDto> items = [];
  @override
  Future<List<ItineraryItemDto>> getItineraryItemsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    return items;
  }
}
