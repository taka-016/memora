import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/transactions/read_transaction.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('RefreshAndroidWidgetItineraryCacheUsecase', () {
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

    test('自動更新で取得結果が空の場合は既存の旅程キャッシュを維持する', () async {
      final existingCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      await usecase.execute(
        groupId: 'group-1',
        preserveExistingCacheOnEmpty: true,
      );

      expect(storage.cache, same(existingCache));
      expect(storage.updateWidgetCount, 1);
    });

    test('選択グループの自動更新オプションで既存表示を維持して再描画を委ねる', () async {
      final existingCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache)
        ..targetGroupId = 'group-1';
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      await usecase.executeForSelectedGroup(
        preserveExistingCacheOnEmpty: true,
        updateWidgetAfterRefresh: false,
      );

      expect(storage.cache, same(existingCache));
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

    test('直近の旅程の再取得に失敗しても予約した新世代で既存表示を維持する', () async {
      final existingCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final generations = _FakeAndroidWidgetCacheGenerationStorage()
        ..caches[0] = existingCache;
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..exception = TestException('取得失敗');
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        _FakeItineraryItemQueryService(),
        generationStorage: generations,
      );

      await expectLater(
        usecase.execute(groupId: 'group-1'),
        throwsA(isA<TestException>()),
      );

      expect(generations.generation, 1);
      expect(
        generations.currentCache?.itineraryDates,
        existingCache.itineraryDates,
      );
    });

    test('古い更新の完了後も新しく選択した対象グループとキャッシュを維持する', () async {
      final oldReadStarted = Completer<void>();
      final releaseOldRead = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-a';
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..beforeReturn = (groupId) async {
          if (groupId != 'group-a') return;
          oldReadStarted.complete();
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

    test('公開可否の確認直後に対象が変わっても新しいグループのキャッシュを維持する', () async {
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
      expect(storage.cache?.groupId, 'group-b');
    });

    test('対象変更後の再取得は公開トランザクション終了後に実行する', () async {
      late final _FakeAndroidWidgetCacheStorage storage;
      storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-a'
        ..afterTargetRead = (readCount) async {
          if (readCount == 2) {
            storage.targetGroupId = 'group-b';
          }
        };
      final readTransaction = _RejectNestedReadTransaction();
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
        readTransaction: readTransaction,
      );

      await usecase.executeForSelectedGroup();

      expect(readTransaction.maxPublishDepth, 1);
      expect(storage.cache?.groupId, 'group-b');
    });

    test('対象変更後に古い更新が完了しても現世代のキャッシュを上書きしない', () async {
      final oldPublishChecked = Completer<void>();
      final releaseOldPublish = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-a'
        ..afterTargetRead = (readCount) async {
          if (readCount != 2) return;
          oldPublishChecked.complete();
          await releaseOldPublish.future;
        };
      final generations = _FakeAndroidWidgetCacheGenerationStorage();
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
        generationStorage: generations,
      );

      final oldRefresh = usecase.executeForSelectedGroup();
      await oldPublishChecked.future;
      await storage.clear();
      await storage.saveTargetGroupId('group-b');
      await generations.advanceCacheGeneration();
      await usecase.executeForSelectedGroup();
      releaseOldPublish.complete();
      await oldRefresh;

      expect(generations.currentCache?.groupId, 'group-b');
      expect(generations.caches[1]?.groupId, 'group-a');
      expect(generations.caches[3]?.sourceMode, AppMode.offline);
    });

    test('同じ対象の新しい更新が先に完了しても古い取得結果で上書きしない', () async {
      final oldReadStarted = Completer<void>();
      final releaseOldRead = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-1';
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..responses = [
          [_trip(name: '変更前')],
          [_trip(name: '変更後')],
        ]
        ..beforeReturn = (_) async {
          if (oldReadStarted.isCompleted) return;
          oldReadStarted.complete();
          await releaseOldRead.future;
        };
      final itineraryItemQueryService = _FakeItineraryItemQueryService()
        ..items = [_item()];
      final generations = _FakeAndroidWidgetCacheGenerationStorage();
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        itineraryItemQueryService,
        generationStorage: generations,
      );

      final oldRefresh = usecase.executeForSelectedGroup();
      await oldReadStarted.future;
      await usecase.executeForSelectedGroup();
      releaseOldRead.complete();
      await oldRefresh;

      expect(generations.currentCache?.itineraryDates.single.tripName, '変更後');
    });

    test('世代予約直前に選択日が変わった場合は最新の選択日を維持する', () async {
      final initialCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        generation: 0,
        groupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-24',
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: [
          _itineraryDate('trip-1_2026-05-24', DateTime(2026, 5, 24)),
          _itineraryDate('trip-1_2026-05-25', DateTime(2026, 5, 25)),
        ],
      );
      final laterOperationCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        generation: 0,
        groupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-25',
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: initialCache.itineraryDates,
      );
      final storage = _FakeAndroidWidgetCacheStorage(cache: initialCache)
        ..targetGroupId = 'group-1'
        ..selectedItineraryDateId = initialCache.selectedItineraryDateId;
      final generations = _FakeAndroidWidgetCacheGenerationStorage()
        ..caches[0] = initialCache
        ..cachePublishedBeforeNextAdvance = laterOperationCache;
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..responses = [
          [_trip(name: '旅行')],
        ];
      final itineraryItemQueryService = _FakeItineraryItemQueryService()
        ..items = [
          _itemAt(DateTime(2026, 5, 24, 10)),
          _itemAt(DateTime(2026, 5, 25, 10)),
        ];
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        itineraryItemQueryService,
        generationStorage: generations,
      );

      await usecase.executeForSelectedGroup();

      expect(
        generations.currentCache?.selectedItineraryDateId,
        'trip-1_2026-05-25',
      );
    });
  });

  group('MoveAndroidWidgetSelectedItineraryDateUsecase', () {
    test('キャッシュ内の日付を移動すると選択世代を進める', () async {
      final storage = _FakeAndroidWidgetCacheStorage(
        cache: AndroidWidgetItineraryCacheDto(
          version: 1,
          sourceMode: AppMode.offline,
          generation: 0,
          groupId: 'group-1',
          selectedItineraryDateId: 'trip-1_2026-05-24',
          lastUpdatedAt: DateTime(2026, 5, 24, 10),
          itineraryDates: [
            _itineraryDate('trip-1_2026-05-24', DateTime(2026, 5, 24)),
            _itineraryDate('trip-1_2026-05-25', DateTime(2026, 5, 25)),
          ],
        ),
      );
      final generations = _FakeAndroidWidgetCacheGenerationStorage()
        ..caches[0] = storage.cache!;
      final usecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: storage,
        cacheGenerationStorage: generations,
        tripEntryQueryService: _FakeTripEntryQueryService(),
        itineraryItemQueryService: _FakeItineraryItemQueryService(),
        refreshCacheUsecase: _buildRefreshUsecase(
          storage,
          _FakeTripEntryQueryService(),
          _FakeItineraryItemQueryService(),
          generationStorage: generations,
        ),
      );

      expect(
        await usecase.execute(AndroidWidgetItineraryDateMoveDirection.next),
        isTrue,
      );
      expect(generations.generation, 1);
      expect(
        generations.currentCache?.selectedItineraryDateId,
        'trip-1_2026-05-25',
      );
    });

    test('別更新と競合しても最新キャッシュ上で次の日へ移動する', () async {
      final initialCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        generation: 0,
        groupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-24',
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: [
          _itineraryDate('trip-1_2026-05-24', DateTime(2026, 5, 24)),
          _itineraryDate('trip-1_2026-05-25', DateTime(2026, 5, 25)),
        ],
      );
      final storage = _FakeAndroidWidgetCacheStorage(cache: initialCache);
      final generations = _FakeAndroidWidgetCacheGenerationStorage()
        ..caches[0] = initialCache
        ..cachePublishedBeforeNextAdvance = initialCache;
      final usecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: storage,
        cacheGenerationStorage: generations,
        tripEntryQueryService: _FakeTripEntryQueryService(),
        itineraryItemQueryService: _FakeItineraryItemQueryService(),
        refreshCacheUsecase: _buildRefreshUsecase(
          storage,
          _FakeTripEntryQueryService(),
          _FakeItineraryItemQueryService(),
          generationStorage: generations,
        ),
      );

      expect(
        await usecase.execute(AndroidWidgetItineraryDateMoveDirection.next),
        isTrue,
      );
      expect(
        generations.currentCache?.selectedItineraryDateId,
        'trip-1_2026-05-25',
      );
    });

    test('キャッシュ外探索中に後発操作が完了した場合はその選択日を維持する', () async {
      final initialCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        generation: 0,
        groupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-24',
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: [
          _itineraryDate('trip-1_2026-05-24', DateTime(2026, 5, 24)),
        ],
      );
      final laterOperationCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        generation: 0,
        groupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-23',
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: [
          _itineraryDate('trip-1_2026-05-23', DateTime(2026, 5, 23)),
          _itineraryDate('trip-1_2026-05-24', DateTime(2026, 5, 24)),
        ],
      );
      final remoteReadStarted = Completer<void>();
      final releaseRemoteRead = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage(cache: initialCache);
      final generations = _FakeAndroidWidgetCacheGenerationStorage()
        ..caches[0] = initialCache;
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..responses = [
          [_trip(name: '旅行')],
          [_trip(name: '旅行')],
        ]
        ..beforeReturn = (_) async {
          if (remoteReadStarted.isCompleted) return;
          remoteReadStarted.complete();
          await releaseRemoteRead.future;
        };
      final itineraryItemQueryService = _FakeItineraryItemQueryService()
        ..items = [
          _itemAt(DateTime(2026, 5, 24, 10)),
          _itemAt(DateTime(2026, 5, 25, 10)),
        ];
      final usecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: storage,
        cacheGenerationStorage: generations,
        tripEntryQueryService: tripEntryQueryService,
        itineraryItemQueryService: itineraryItemQueryService,
        refreshCacheUsecase: _buildRefreshUsecase(
          storage,
          tripEntryQueryService,
          itineraryItemQueryService,
          generationStorage: generations,
        ),
      );

      final firstMove = usecase.execute(
        AndroidWidgetItineraryDateMoveDirection.next,
      );
      await remoteReadStarted.future;
      await generations.advanceCacheGeneration(
        updateCache: (_) => laterOperationCache,
      );
      releaseRemoteRead.complete();
      await firstMove;

      expect(
        generations.currentCache?.selectedItineraryDateId,
        'trip-1_2026-05-23',
      );
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
        tripEntryQueryService: tripEntryQueryService,
        itineraryItemQueryService: itineraryItemQueryService,
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

AndroidWidgetItineraryDateCacheDto _itineraryDate(String id, DateTime date) {
  return AndroidWidgetItineraryDateCacheDto(
    id: id,
    tripId: 'trip-1',
    tripName: '旅行',
    tripPeriodLabel: '2026/5/24 - 2026/5/25',
    dateLabel: '${date.year}/${date.month}/${date.day}',
    date: date,
    itineraryItems: const [],
  );
}

TripEntryDto _trip({required String name}) {
  return TripEntryDto(
    id: 'trip-1',
    groupId: 'group-1',
    year: 2026,
    name: name,
    startDate: DateTime(2026, 5, 24),
    endDate: DateTime(2026, 5, 24),
  );
}

ItineraryItemDto _item() {
  return _itemAt(DateTime(2026, 5, 24, 10));
}

ItineraryItemDto _itemAt(DateTime startDateTime) {
  return ItineraryItemDto(
    id: 'item-1',
    tripId: 'trip-1',
    name: '旅程',
    startDateTime: startDateTime,
  );
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
  AndroidWidgetCacheGenerationStorage? generationStorage,
  ReadTransaction? readTransaction,
}) {
  return RefreshAndroidWidgetItineraryCacheUsecase(
    cacheStorage: storage,
    cacheGenerationStorage: generationStorage,
    mode: AppMode.offline,
    readTransaction: readTransaction,
    getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
      tripEntryQueryService: tripEntryQueryService,
      itineraryItemQueryService: itineraryItemQueryService,
      clock: FixedAppClock(DateTime(2026, 5, 24, 10)),
    ),
  );
}

class _RejectNestedReadTransaction implements ReadTransaction {
  var _publishDepth = 0;
  var maxPublishDepth = 0;

  @override
  Future<T> execute<T>(Future<T> Function() action) => action();

  @override
  Future<void> executeAndPublish<T>({
    required Future<T> Function() read,
    required Future<void> Function(T value) publish,
  }) async {
    if (_publishDepth > 0) {
      throw TestException('公開トランザクションがネストしました');
    }
    final value = await read();
    _publishDepth += 1;
    maxPublishDepth = maxPublishDepth < _publishDepth
        ? _publishDepth
        : maxPublishDepth;
    try {
      await publish(value);
    } finally {
      _publishDepth -= 1;
    }
  }
}

class _FakeAndroidWidgetCacheGenerationStorage
    implements AndroidWidgetCacheGenerationStorage {
  int generation = 0;
  final caches = <int, AndroidWidgetItineraryCacheDto>{};
  AndroidWidgetItineraryCacheDto? cachePublishedBeforeNextAdvance;

  AndroidWidgetItineraryCacheDto? get currentCache => caches[generation];

  @override
  Future<int> advanceCacheGeneration({
    AndroidWidgetItineraryCacheDto? Function(
      AndroidWidgetItineraryCacheDto? currentCache,
    )?
    updateCache,
  }) async {
    final concurrentlyPublishedCache = cachePublishedBeforeNextAdvance;
    if (concurrentlyPublishedCache != null) {
      generation += 1;
      caches[generation] = _cacheWithGeneration(
        concurrentlyPublishedCache,
        generation,
      );
      cachePublishedBeforeNextAdvance = null;
    }
    final cacheToCarry = updateCache?.call(currentCache);
    generation += 1;
    if (cacheToCarry != null) {
      caches[generation] = _cacheWithGeneration(cacheToCarry, generation);
    }
    return generation;
  }

  AndroidWidgetItineraryCacheDto _cacheWithGeneration(
    AndroidWidgetItineraryCacheDto cache,
    int nextGeneration,
  ) {
    return AndroidWidgetItineraryCacheDto(
      version: cache.version,
      sourceMode: cache.sourceMode,
      generation: nextGeneration,
      groupId: cache.groupId,
      selectedItineraryDateId: cache.selectedItineraryDateId,
      lastUpdatedAt: cache.lastUpdatedAt,
      itineraryDates: cache.itineraryDates,
    );
  }

  @override
  Future<int> getCacheGeneration() async => generation;

  @override
  Future<void> saveItineraryCacheForGeneration(
    AndroidWidgetItineraryCacheDto cache,
  ) async {
    caches[cache.generation] = cache;
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
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {
    selectedItineraryDateId = itineraryDateId;
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
  Object? exception;
  Future<void> Function(String groupId)? beforeReturn;
  List<List<TripEntryDto>> responses = const [];
  int callCount = 0;

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
    final callIndex = callCount++;
    final response = callIndex < responses.length
        ? responses[callIndex]
        : const <TripEntryDto>[];
    await beforeReturn?.call(groupId);
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    return response;
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
  List<ItineraryItemDto> items = const [];

  @override
  Future<List<ItineraryItemDto>> getItineraryItemsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    return items;
  }
}
