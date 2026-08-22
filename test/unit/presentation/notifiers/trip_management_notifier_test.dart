import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/trip/trip_entry_mutation_coordinator.dart';
import 'package:memora/presentation/notifiers/trip_management_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_exception.dart';
import 'trip_management_notifier_test.mocks.dart';

@GenerateMocks([
  GetTripEntriesUsecase,
  GetGroupWithMembersByIdUsecase,
  TripEntryMutationCoordinator,
])
void main() {
  const query = TripManagementQuery(groupId: 'group-1', year: 2025);
  const trip = TripEntryDto(
    id: 'trip-1',
    groupId: 'group-1',
    year: 2025,
    name: '北海道旅行',
  );
  const createdTrip = TripEntryDto(
    id: '',
    groupId: 'group-1',
    year: 2025,
    name: '沖縄旅行',
  );
  const updatedTrip = TripEntryDto(
    id: 'trip-1',
    groupId: 'group-1',
    year: 2025,
    name: '更新後の北海道旅行',
  );
  const member = GroupMemberDto(
    memberId: 'member-1',
    groupId: 'group-1',
    displayName: '太郎',
  );
  const loadedGroupDto = GroupDto(
    id: 'group-1',
    ownerId: 'member-1',
    name: '家族',
    members: [member],
  );

  late MockGetTripEntriesUsecase getTripEntriesUsecase;
  late MockGetGroupWithMembersByIdUsecase getGroupUsecase;
  late MockTripEntryMutationCoordinator mutationCoordinator;
  late ProviderContainer container;

  setUp(() {
    AppLogger.suppressLogging(true);
    getTripEntriesUsecase = MockGetTripEntriesUsecase();
    getGroupUsecase = MockGetGroupWithMembersByIdUsecase();
    mutationCoordinator = MockTripEntryMutationCoordinator();
    container = ProviderContainer(
      overrides: [
        getTripEntriesUsecaseProvider.overrideWithValue(getTripEntriesUsecase),
        getGroupWithMembersByIdUsecaseProvider.overrideWithValue(
          getGroupUsecase,
        ),
        tripEntryMutationCoordinatorProvider.overrideWithValue(
          mutationCoordinator,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    AppLogger.suppressLogging(false);
  });

  ProviderSubscription<TripManagementState> listenProvider() {
    final provider = tripManagementNotifierProvider(query);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    return subscription;
  }

  Future<void> waitForInitialLoad() async {
    final completer = Completer<void>();
    final subscription = container.listen(
      tripManagementNotifierProvider(query),
      (_, next) {
        if (!next.isInitialLoading && !completer.isCompleted) {
          completer.complete();
        }
      },
      fireImmediately: true,
    );
    await completer.future;
    subscription.close();
  }

  Future<TripManagementNotifier> startNotifier({
    List<TripEntryDto> trips = const [trip],
    GroupDto? loadedGroup = loadedGroupDto,
  }) async {
    when(
      getTripEntriesUsecase.execute(query.groupId, query.year),
    ).thenAnswer((_) async => trips);
    when(
      getGroupUsecase.execute(
        query.groupId,
        membersSort: GroupMemberSort.displayOrder,
      ),
    ).thenAnswer((_) async => loadedGroup);
    listenProvider();
    await waitForInitialLoad();
    return container.read(tripManagementNotifierProvider(query).notifier);
  }

  group('TripManagementNotifier', () {
    test('旅行一覧とグループメンバーを並行取得し、取得元ごとに完了状態を反映する', () async {
      final tripsCompleter = Completer<List<TripEntryDto>>();
      final groupCompleter = Completer<GroupDto?>();
      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenAnswer((_) => tripsCompleter.future);
      when(
        getGroupUsecase.execute(
          query.groupId,
          membersSort: GroupMemberSort.displayOrder,
        ),
      ).thenAnswer((_) => groupCompleter.future);

      listenProvider();
      await Future<void>.delayed(Duration.zero);

      verify(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).called(1);
      verify(
        getGroupUsecase.execute(
          query.groupId,
          membersSort: GroupMemberSort.displayOrder,
        ),
      ).called(1);

      tripsCompleter.complete(const [trip]);
      await container.pump();

      var state = container.read(tripManagementNotifierProvider(query));
      expect(state.tripEntries, const [trip]);
      expect(state.tripEntriesStatus, TripManagementLoadStatus.success);
      expect(state.groupMembersStatus, TripManagementLoadStatus.initialLoading);

      groupCompleter.complete(loadedGroupDto);
      await container.pump();

      state = container.read(tripManagementNotifierProvider(query));
      expect(state.groupMembers, const [member]);
      expect(state.groupMembersStatus, TripManagementLoadStatus.success);
    });

    test('旅行一覧だけが失敗してもメンバーを維持し、旅行一覧だけを再試行する', () async {
      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenThrow(TestException('旅行取得失敗'));
      when(
        getGroupUsecase.execute(
          query.groupId,
          membersSort: GroupMemberSort.displayOrder,
        ),
      ).thenAnswer((_) async => loadedGroupDto);
      listenProvider();
      await waitForInitialLoad();

      var state = container.read(tripManagementNotifierProvider(query));
      expect(state.tripEntriesStatus, TripManagementLoadStatus.error);
      expect(state.groupMembers, const [member]);
      expect(state.groupMembersStatus, TripManagementLoadStatus.success);

      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenAnswer((_) async => const [trip]);
      final notifier = container.read(
        tripManagementNotifierProvider(query).notifier,
      );

      expect(await notifier.retryTripEntries(), isTrue);

      state = container.read(tripManagementNotifierProvider(query));
      expect(state.tripEntries, const [trip]);
      expect(state.tripEntriesStatus, TripManagementLoadStatus.success);
      verify(
        getGroupUsecase.execute(
          query.groupId,
          membersSort: GroupMemberSort.displayOrder,
        ),
      ).called(1);
    });

    test('メンバー再取得失敗時は取得済みメンバーを維持し、個別に再試行できる', () async {
      final notifier = await startNotifier();
      when(
        getGroupUsecase.execute(
          query.groupId,
          membersSort: GroupMemberSort.displayOrder,
        ),
      ).thenThrow(TestException('メンバー再取得失敗'));

      expect(await notifier.retryGroupMembers(), isTrue);

      final state = container.read(tripManagementNotifierProvider(query));
      expect(state.groupMembers, const [member]);
      expect(state.groupMembersStatus, TripManagementLoadStatus.error);
      expect(state.tripEntries, const [trip]);
    });

    test('作成成功後に旅行一覧だけを再取得する', () async {
      final notifier = await startNotifier();
      clearInteractions(getTripEntriesUsecase);
      clearInteractions(getGroupUsecase);
      when(
        mutationCoordinator.createTripEntry(createdTrip),
      ).thenAnswer((_) async => 'trip-2');
      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenAnswer((_) async => const [trip, createdTrip]);

      expect(await notifier.createTripEntry(createdTrip), isTrue);

      expect(
        container.read(tripManagementNotifierProvider(query)).tripEntries,
        const [trip, createdTrip],
      );
      verifyInOrder([
        mutationCoordinator.createTripEntry(createdTrip),
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ]);
      verifyNever(
        getGroupUsecase.execute(any, membersSort: anyNamed('membersSort')),
      );
    });

    test('更新成功後に旅行一覧だけを再取得する', () async {
      final notifier = await startNotifier();
      clearInteractions(getTripEntriesUsecase);
      clearInteractions(getGroupUsecase);
      when(
        mutationCoordinator.updateTripEntry(updatedTrip),
      ).thenAnswer((_) async {});
      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenAnswer((_) async => const [updatedTrip]);

      expect(await notifier.updateTripEntry(updatedTrip), isTrue);

      expect(
        container.read(tripManagementNotifierProvider(query)).tripEntries,
        const [updatedTrip],
      );
      verifyInOrder([
        mutationCoordinator.updateTripEntry(updatedTrip),
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ]);
      verifyNever(
        getGroupUsecase.execute(any, membersSort: anyNamed('membersSort')),
      );
    });

    test('更新成功後の一覧再取得が失敗しても取得済み一覧を維持する', () async {
      final notifier = await startNotifier();
      when(
        mutationCoordinator.updateTripEntry(updatedTrip),
      ).thenAnswer((_) async {});
      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenThrow(TestException('再取得失敗'));

      expect(await notifier.updateTripEntry(updatedTrip), isTrue);

      final state = container.read(tripManagementNotifierProvider(query));
      expect(state.tripEntries, const [trip]);
      expect(state.tripEntriesStatus, TripManagementLoadStatus.error);
    });

    test('削除成功後に旅行一覧だけを再取得する', () async {
      final notifier = await startNotifier();
      clearInteractions(getTripEntriesUsecase);
      clearInteractions(getGroupUsecase);
      when(
        mutationCoordinator.deleteTripEntry(trip.id),
      ).thenAnswer((_) async {});
      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenAnswer((_) async => const []);

      expect(await notifier.deleteTripEntry(trip.id), isTrue);

      expect(
        container.read(tripManagementNotifierProvider(query)).tripEntries,
        isEmpty,
      );
      verifyInOrder([
        mutationCoordinator.deleteTripEntry(trip.id),
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ]);
      verifyNever(
        getGroupUsecase.execute(any, membersSort: anyNamed('membersSort')),
      );
    });

    test('更新失敗時は一覧を再取得せず例外を呼び出し元へ伝播する', () async {
      final notifier = await startNotifier();
      clearInteractions(getTripEntriesUsecase);
      when(
        mutationCoordinator.updateTripEntry(updatedTrip),
      ).thenThrow(TestException('更新失敗'));

      await expectLater(
        notifier.updateTripEntry(updatedTrip),
        throwsA(isA<TestException>()),
      );

      expect(
        container.read(tripManagementNotifierProvider(query)).tripEntries,
        const [trip],
      );
      verifyNever(getTripEntriesUsecase.execute(any, any));
    });

    test('更新中の再取得要求と重複する更新要求を無視する', () async {
      final notifier = await startNotifier();
      final updateCompleter = Completer<void>();
      when(
        mutationCoordinator.updateTripEntry(updatedTrip),
      ).thenAnswer((_) => updateCompleter.future);
      when(
        getTripEntriesUsecase.execute(query.groupId, query.year),
      ).thenAnswer((_) async => const [updatedTrip]);

      final firstUpdate = notifier.updateTripEntry(updatedTrip);

      expect(await notifier.retryTripEntries(), isFalse);
      expect(await notifier.updateTripEntry(updatedTrip), isFalse);
      verify(mutationCoordinator.updateTripEntry(updatedTrip)).called(1);

      updateCompleter.complete();
      expect(await firstUpdate, isTrue);
    });
  });
}
