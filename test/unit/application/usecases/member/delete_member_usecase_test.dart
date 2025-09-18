import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/repositories/trip_participant_repository.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/member_event_repository.dart';

import 'delete_member_usecase_test.mocks.dart';

@GenerateMocks([
  MemberRepository,
  TripParticipantRepository,
  GroupRepository,
  MemberEventRepository,
])
void main() {
  late DeleteMemberUsecase usecase;
  late MockMemberRepository mockMemberRepository;
  late MockTripParticipantRepository mockTripParticipantRepository;
  late MockGroupRepository mockGroupRepository;
  late MockMemberEventRepository mockMemberEventRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    mockTripParticipantRepository = MockTripParticipantRepository();
    mockGroupRepository = MockGroupRepository();
    mockMemberEventRepository = MockMemberEventRepository();
    usecase = DeleteMemberUsecase(
      mockMemberRepository,
      mockTripParticipantRepository,
      mockGroupRepository,
      mockMemberEventRepository,
    );
  });

  group('DeleteMemberUsecase', () {
    test('リポジトリからメンバーを削除すること', () async {
      // arrange
      const memberId = 'member123';

      when(
        mockMemberRepository.deleteMember(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      ).thenAnswer((_) async => {});

      when(
        mockGroupRepository.deleteGroupMembersByMemberId(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockMemberEventRepository.deleteMemberEventsByMemberId(memberId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(memberId);

      // assert
      verify(mockMemberRepository.deleteMember(memberId));
    });

    test('有効なメンバーIDに対してエラーなく完了すること', () async {
      // arrange
      const memberId = 'member123';

      when(
        mockMemberRepository.deleteMember(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      ).thenAnswer((_) async => {});

      when(
        mockGroupRepository.deleteGroupMembersByMemberId(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockMemberEventRepository.deleteMemberEventsByMemberId(memberId),
      ).thenAnswer((_) async => {});

      // act & assert
      expect(() => usecase.execute(memberId), returnsNormally);
    });

    test('メンバー削除時に旅行参加者も削除されること', () async {
      // arrange
      const memberId = 'member123';

      when(
        mockMemberRepository.deleteMember(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      ).thenAnswer((_) async => {});

      when(
        mockGroupRepository.deleteGroupMembersByMemberId(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockMemberEventRepository.deleteMemberEventsByMemberId(memberId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(memberId);

      // assert
      verify(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      );
      verify(mockMemberRepository.deleteMember(memberId));
    });

    test('メンバー削除時にグループメンバーも削除されること', () async {
      // arrange
      const memberId = 'member123';

      when(
        mockMemberRepository.deleteMember(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      ).thenAnswer((_) async => {});

      when(
        mockGroupRepository.deleteGroupMembersByMemberId(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockMemberEventRepository.deleteMemberEventsByMemberId(memberId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(memberId);

      // assert
      verify(mockGroupRepository.deleteGroupMembersByMemberId(memberId));
    });

    test('メンバー削除時にメンバーイベントも削除されること', () async {
      // arrange
      const memberId = 'member123';

      when(
        mockMemberRepository.deleteMember(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      ).thenAnswer((_) async => {});

      when(
        mockGroupRepository.deleteGroupMembersByMemberId(memberId),
      ).thenAnswer((_) async => {});

      when(
        mockMemberEventRepository.deleteMemberEventsByMemberId(memberId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(memberId);

      // assert
      verify(mockMemberEventRepository.deleteMemberEventsByMemberId(memberId));
    });
  });
}
