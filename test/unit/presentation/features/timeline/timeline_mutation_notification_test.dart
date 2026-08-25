import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_mutation_coordinator.dart';
import 'package:memora/presentation/features/timeline/timeline_dvc_point_usages_provider.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_entries_provider.dart';
import 'package:memora/presentation/features/trip/trip_entry_mutation_coordinator.dart';

void main() {
  test('旅行の作成・更新・削除後に年表の旅行Providerを再取得する', () async {
    final queryService = _CountingTripEntryQueryService();
    final container = ProviderContainer(
      overrides: [
        tripEntryQueryServiceProvider.overrideWithValue(queryService),
        tripEntryRepositoryProvider.overrideWithValue(
          _FakeTripEntryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    const query = TimelineTripEntriesQuery(groupId: 'group-1', year: 2026);
    final subscription = container.listen(
      timelineTripEntriesProvider(query),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(timelineTripEntriesProvider(query).future);
    final coordinator = container.read(tripEntryMutationCoordinatorProvider);
    const trip = TripEntryDto(
      id: 'trip-1',
      groupId: 'group-1',
      year: 2026,
      name: '旅行',
    );

    await coordinator.createTripEntry(trip.copyWith(id: ''));
    await container.read(timelineTripEntriesProvider(query).future);
    await coordinator.updateTripEntry(trip);
    await container.read(timelineTripEntriesProvider(query).future);
    await coordinator.deleteTripEntry(trip.id);
    await container.read(timelineTripEntriesProvider(query).future);

    expect(queryService.callCount, 4);
  });

  test('DVC利用履歴の保存・削除後に年表のDVCProviderを再取得する', () async {
    final queryService = _CountingDvcPointUsageQueryService();
    final container = ProviderContainer(
      overrides: [
        dvcPointUsageQueryServiceProvider.overrideWithValue(queryService),
        dvcPointUsageRepositoryProvider.overrideWithValue(
          _FakeDvcPointUsageRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      timelineDvcPointUsagesByYearProvider('group-1'),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(
      timelineDvcPointUsagesByYearProvider('group-1').future,
    );
    final coordinator = container.read(
      dvcPointUsageMutationCoordinatorProvider,
    );
    final usage = DvcPointUsageDto(
      id: 'usage-1',
      groupId: 'group-1',
      usageYearMonth: DateTime(2026, 4),
      usedPoint: 10,
    );

    await coordinator.saveDvcPointUsage(usage);
    await container.read(
      timelineDvcPointUsagesByYearProvider('group-1').future,
    );
    await coordinator.deleteDvcPointUsage(usage.id);
    await container.read(
      timelineDvcPointUsagesByYearProvider('group-1').future,
    );

    expect(queryService.callCount, 3);
  });
}

class _CountingTripEntryQueryService implements TripEntryQueryService {
  int callCount = 0;

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    callCount++;
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

class _CountingDvcPointUsageQueryService implements DvcPointUsageQueryService {
  int callCount = 0;

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    callCount++;
    return [];
  }
}

class _FakeTripEntryRepository implements TripEntryRepository {
  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async => 'trip-1';

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {}

  @override
  Future<void> deleteTripEntry(String tripId) async {}

  @override
  Future<void> deleteTripEntriesByGroupId(String groupId) async {}
}

class _FakeDvcPointUsageRepository implements DvcPointUsageRepository {
  @override
  Future<void> saveDvcPointUsage(DvcPointUsage pointUsage) async {}

  @override
  Future<void> deleteDvcPointUsage(String pointUsageId) async {}

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async {}
}
