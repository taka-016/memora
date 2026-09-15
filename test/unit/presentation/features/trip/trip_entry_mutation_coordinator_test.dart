import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/trip/trip_entry_mutation_coordinator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'trip_entry_mutation_coordinator_test.mocks.dart';

@GenerateNiceMocks([MockSpec<TripEntryRepository>()])
void main() {
  const trip = TripEntryDto(id: 'trip', groupId: 'group', year: 2026);
  late MockTripEntryRepository repository;
  late ProviderContainer container;
  late List<String> events;
  Object? refreshFailure;

  setUp(() {
    events = [];
    refreshFailure = null;
    repository = MockTripEntryRepository();
    when(repository.saveTripEntry(any)).thenAnswer((_) async {
      events.add('保存');
      return 'new-trip';
    });
    when(repository.updateTripEntry(any)).thenAnswer((_) async {
      events.add('更新');
    });
    when(repository.deleteTripEntry(any)).thenAnswer((_) async {
      events.add('削除');
    });
    container = ProviderContainer(
      overrides: [
        tripEntryRepositoryProvider.overrideWithValue(repository),
        refreshSelectedAndroidWidgetCacheProvider.overrideWithValue(() async {
          events.add('ウィジェット更新');
          if (refreshFailure != null) throw refreshFailure!;
        }),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('旅行と旅程の作成・更新・削除の成功後にウィジェットを更新する', () async {
    final coordinator = container.read(tripEntryMutationCoordinatorProvider);
    expect(await coordinator.createTripEntry(trip), 'new-trip');
    await coordinator.updateTripEntry(trip);
    await coordinator.deleteTripEntry(trip.id);
    expect(events, ['保存', 'ウィジェット更新', '更新', 'ウィジェット更新', '削除', 'ウィジェット更新']);
  });

  test('旅行の保存失敗時はウィジェットを更新しない', () async {
    final failure = TestException('保存失敗');
    when(repository.updateTripEntry(any)).thenThrow(failure);
    await expectLater(
      container
          .read(tripEntryMutationCoordinatorProvider)
          .updateTripEntry(trip),
      throwsA(same(failure)),
    );
    expect(events, isEmpty);
  });

  test('ウィジェット更新失敗を保存失敗として扱わず重複作成を防ぐ', () async {
    refreshFailure = TestException('ウィジェット更新失敗');
    final coordinator = container.read(tripEntryMutationCoordinatorProvider);
    expect(await coordinator.createTripEntry(trip), 'new-trip');
    await coordinator.updateTripEntry(trip);
    await coordinator.deleteTripEntry(trip.id);
    verify(repository.saveTripEntry(any)).called(1);
    expect(events.where((e) => e == 'ウィジェット更新'), hasLength(3));
  });
}
