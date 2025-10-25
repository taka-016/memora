import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

import 'delete_group_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository, GroupEventRepository, TripEntryRepository])
void main() {
  late DeleteGroupUsecase usecase;
  late MockGroupRepository mockGroupRepository;
  late MockGroupEventRepository mockGroupEventRepository;
  late MockTripEntryRepository mockTripEntryRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockGroupEventRepository = MockGroupEventRepository();
    mockTripEntryRepository = MockTripEntryRepository();
    usecase = DeleteGroupUsecase(
      mockGroupRepository,
      mockGroupEventRepository,
      mockTripEntryRepository,
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
  });
}
