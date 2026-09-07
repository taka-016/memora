import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/timeline/timeline_dvc_point_usages_provider.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_entries_provider.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('timelineTripEntriesProvider', () {
    test('同じ条件はキャッシュを共有しグループIDと年ごとに分離して年表更新時に再取得する', () async {
      final queryService = _FakeTripEntryQueryService();
      final container = ProviderContainer(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(queryService),
        ],
      );
      addTearDown(container.dispose);
      const conditions = [
        ('group-1', 2025),
        ('group-1', 2026),
        ('group-2', 2025),
      ];
      for (final (groupId, year) in conditions) {
        final provider = timelineTripEntriesProvider(
          groupId: groupId,
          year: year,
        );
        final subscription = container.listen(provider, (_, _) {});
        addTearDown(subscription.close);
        await container.read(provider.future);
      }
      for (final (groupId, year) in conditions) {
        await container.read(
          timelineTripEntriesProvider(groupId: groupId, year: year).future,
        );
      }
      expect(queryService.requestedQueries, conditions);

      container.invalidate(timelineRowsRefreshProvider);
      for (final (groupId, year) in conditions) {
        await container.read(
          timelineTripEntriesProvider(groupId: groupId, year: year).future,
        );
      }
      expect(queryService.requestedQueries, [...conditions, ...conditions]);
    });

    test('監視がなくなるとキャッシュを破棄し再監視時に取得する', () async {
      final queryService = _FakeTripEntryQueryService();
      final container = ProviderContainer(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(queryService),
        ],
      );
      addTearDown(container.dispose);
      final provider = timelineTripEntriesProvider(
        groupId: 'group-1',
        year: 2025,
      );
      final subscription = container.listen(provider, (_, _) {});
      await container.read(provider.future);

      subscription.close();
      await container.pump();

      final nextSubscription = container.listen(provider, (_, _) {});
      addTearDown(nextSubscription.close);
      await container.read(provider.future);

      expect(queryService.requestedQueries, [
        ('group-1', 2025),
        ('group-1', 2025),
      ]);
    });

    test('取得失敗後に対象条件だけを無効化して再試行できる', () async {
      final queryService = _FakeTripEntryQueryService(
        exception: TestException('取得失敗'),
      );
      var containerRetryCount = 0;
      final container = ProviderContainer(
        retry: (_, _) {
          containerRetryCount++;
          return null;
        },
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(queryService),
        ],
      );
      addTearDown(container.dispose);
      final provider = timelineTripEntriesProvider(
        groupId: 'group-1',
        year: 2025,
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await expectLater(
        container.read(provider.future),
        throwsA(isA<TestException>()),
      );
      expect(containerRetryCount, 0);
      expect(queryService.requestedQueries, [('group-1', 2025)]);
      queryService.exception = null;
      container.invalidate(provider);

      await expectLater(container.read(provider.future), completion(isEmpty));
      expect(queryService.requestedQueries, [
        ('group-1', 2025),
        ('group-1', 2025),
      ]);
    });
  });

  group('timelineDvcPointUsagesByYearProvider', () {
    test('グループの全期間データを1回取得して年別に保持する', () async {
      final queryService = _FakeDvcPointUsageQueryService([
        DvcPointUsageDto(
          id: 'usage-2',
          groupId: 'group-1',
          usageYearMonth: DateTime(2025, 8),
          usedPoint: 20,
        ),
        DvcPointUsageDto(
          id: 'usage-1',
          groupId: 'group-1',
          usageYearMonth: DateTime(2025, 4),
          usedPoint: 10,
        ),
        DvcPointUsageDto(
          id: 'usage-3',
          groupId: 'group-1',
          usageYearMonth: DateTime(2026, 1),
          usedPoint: 30,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          dvcPointUsageQueryServiceProvider.overrideWithValue(queryService),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        timelineDvcPointUsagesByYearProvider('group-1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      final result = await container.read(
        timelineDvcPointUsagesByYearProvider('group-1').future,
      );

      expect(result[2025]?.map((usage) => usage.id), ['usage-1', 'usage-2']);
      expect(result[2026]?.map((usage) => usage.id), ['usage-3']);
      expect(queryService.requestedGroupIds, ['group-1']);
    });
  });
}

class _FakeTripEntryQueryService implements TripEntryQueryService {
  _FakeTripEntryQueryService({this.exception});

  Object? exception;
  final List<(String, int)> requestedQueries = [];

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    requestedQueries.add((groupId, year));
    final currentException = exception;
    if (currentException != null) {
      throw currentException;
    }
    return [];
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async => [];

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async => null;
}

class _FakeDvcPointUsageQueryService implements DvcPointUsageQueryService {
  _FakeDvcPointUsageQueryService(this.usages);

  final List<DvcPointUsageDto> usages;
  final List<String> requestedGroupIds = [];

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    requestedGroupIds.add(groupId);
    return usages;
  }
}
