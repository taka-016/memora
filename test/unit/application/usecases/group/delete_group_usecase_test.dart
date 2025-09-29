import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/group_event_repository.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/repositories/pin_repository.dart';
import 'package:memora/domain/repositories/trip_participant_repository.dart';
import 'package:memora/domain/entities/trip_entry.dart';

import 'delete_group_usecase_test.mocks.dart';

@GenerateMocks([
  GroupRepository,
  GroupEventRepository,
  TripEntryRepository,
  PinRepository,
  TripParticipantRepository,
])
void main() {
  late DeleteGroupUsecase usecase;
  late MockGroupRepository mockGroupRepository;
  late MockGroupEventRepository mockGroupEventRepository;
  late MockTripEntryRepository mockTripEntryRepository;
  late MockPinRepository mockPinRepository;
  late MockTripParticipantRepository mockTripParticipantRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockGroupEventRepository = MockGroupEventRepository();
    mockTripEntryRepository = MockTripEntryRepository();
    mockPinRepository = MockPinRepository();
    mockTripParticipantRepository = MockTripParticipantRepository();
    usecase = DeleteGroupUsecase(
      mockGroupRepository,
      mockGroupEventRepository,
      mockTripEntryRepository,
      mockPinRepository,
      mockTripParticipantRepository,
    );
  });

  group('DeleteGroupUsecase', () {
    test('リポジトリからグループを削除すること', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockTripEntryRepository.deleteTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockTripEntryRepository.getTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => []);
      when(
        mockGroupEventRepository.deleteGroupEventsByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(groupId);

      // assert
      verify(mockGroupRepository.deleteGroup(groupId));
    });

    test('有効なグループIDに対してエラーなく完了すること', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockTripEntryRepository.deleteTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockTripEntryRepository.getTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => []);
      when(
        mockGroupEventRepository.deleteGroupEventsByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      // act & assert
      expect(() => usecase.execute(groupId), returnsNormally);
    });

    test('グループ削除時に旅行エントリも削除されること', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockTripEntryRepository.deleteTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockTripEntryRepository.getTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => []);
      when(
        mockGroupEventRepository.deleteGroupEventsByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(groupId);

      // assert
      verify(mockTripEntryRepository.deleteTripEntriesByGroupId(groupId));
    });

    test('グループ削除時にtripIdで紐づくpinsとtrip_participantsも削除されること', () async {
      // arrange
      const groupId = 'group123';
      final now = DateTime.now();
      final tripEntries = [
        TripEntry(
          id: 'trip1',
          groupId: groupId,
          tripName: 'テスト旅行1',
          tripStartDate: now,
          tripEndDate: now,
          tripMemo: null,
        ),
        TripEntry(
          id: 'trip2',
          groupId: groupId,
          tripName: 'テスト旅行2',
          tripStartDate: now,
          tripEndDate: now,
          tripMemo: null,
        ),
      ];

      when(
        mockTripEntryRepository.deleteTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockTripEntryRepository.getTripEntriesByGroupId(groupId),
      ).thenAnswer((_) async => tripEntries);
      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockGroupEventRepository.deleteGroupEventsByGroupId(groupId),
      ).thenAnswer((_) async => {});
      when(
        mockPinRepository.deletePinsByTripId(any),
      ).thenAnswer((_) async => {});
      when(
        mockTripParticipantRepository.deleteTripParticipantsByTripId(any),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(groupId);

      // assert
      verify(mockTripEntryRepository.getTripEntriesByGroupId(groupId));
      verify(mockPinRepository.deletePinsByTripId('trip1'));
      verify(mockPinRepository.deletePinsByTripId('trip2'));
      verify(
        mockTripParticipantRepository.deleteTripParticipantsByTripId('trip1'),
      );
      verify(
        mockTripParticipantRepository.deleteTripParticipantsByTripId('trip2'),
      );
    });
  });
}
