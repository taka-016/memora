import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/timeline/timeline_dvc_point_usages_provider.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_entries_provider.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('timelineTripEntriesProvider', () {
    test('グループIDと年ごとに取得状態を分離する', () async {
      final queryService = _FakeTripEntryQueryService();
      final container = ProviderContainer(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(queryService),
        ],
      );
      addTearDown(container.dispose);
      const firstQuery = TimelineTripEntriesQuery(
        groupId: 'group-1',
        year: 2025,
      );
      const secondQuery = TimelineTripEntriesQuery(
        groupId: 'group-2',
        year: 2026,
      );

      final firstSubscription = container.listen(
        timelineTripEntriesProvider(firstQuery),
        (_, _) {},
      );
      final secondSubscription = container.listen(
        timelineTripEntriesProvider(secondQuery),
        (_, _) {},
      );
      addTearDown(firstSubscription.close);
      addTearDown(secondSubscription.close);

      await container.read(timelineTripEntriesProvider(firstQuery).future);
      await container.read(timelineTripEntriesProvider(secondQuery).future);

      expect(queryService.requestedQueries, [
        ('group-1', 2025),
        ('group-2', 2026),
      ]);
    });

    test('取得失敗後に対象条件だけを無効化して再試行できる', () async {
      final queryService = _FakeTripEntryQueryService(
        exception: TestException('取得失敗'),
      );
      final container = ProviderContainer(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(queryService),
        ],
      );
      addTearDown(container.dispose);
      const query = TimelineTripEntriesQuery(groupId: 'group-1', year: 2025);
      final subscription = container.listen(
        timelineTripEntriesProvider(query),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(timelineTripEntriesProvider(query).future),
        throwsA(isA<TestException>()),
      );
      queryService.exception = null;
      container.invalidate(timelineTripEntriesProvider(query));

      await expectLater(
        container.read(timelineTripEntriesProvider(query).future),
        completion(isEmpty),
      );
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
