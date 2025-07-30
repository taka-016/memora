import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/delete_member_usecase.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/repositories/trip_participant_repository.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';
import 'package:memora/domain/repositories/member_event_repository.dart';

import 'delete_member_usecase_test.mocks.dart';

@GenerateMocks([
  MemberRepository,
  TripParticipantRepository,
  GroupMemberRepository,
  MemberEventRepository,
])
void main() {
  late DeleteMemberUsecase usecase;
  late MockMemberRepository mockMemberRepository;
  late MockTripParticipantRepository mockTripParticipantRepository;
  late MockGroupMemberRepository mockGroupMemberRepository;
  late MockMemberEventRepository mockMemberEventRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    mockTripParticipantRepository = MockTripParticipantRepository();
    mockGroupMemberRepository = MockGroupMemberRepository();
    mockMemberEventRepository = MockMemberEventRepository();
    usecase = DeleteMemberUsecase(
      mockMemberRepository,
      mockTripParticipantRepository,
      mockGroupMemberRepository,
      mockMemberEventRepository,
    );
  });

  group('DeleteMemberUsecase', () {
    test('IDによってメンバーを削除すること', () async {
      // Arrange
      const memberId = 'member-to-delete-id';

      when(mockMemberRepository.deleteMember(any)).thenAnswer((_) async {});
      when(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(any),
      ).thenAnswer((_) async {});
      when(
        mockGroupMemberRepository.deleteGroupMembersByMemberId(any),
      ).thenAnswer((_) async {});
      when(
        mockMemberEventRepository.deleteMemberEventsByMemberId(any),
      ).thenAnswer((_) async {});

      // Act
      await usecase.execute(memberId);

      // Assert
      verify(mockMemberRepository.deleteMember(memberId)).called(1);
      verify(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      ).called(1);
      verify(
        mockGroupMemberRepository.deleteGroupMembersByMemberId(memberId),
      ).called(1);
      verify(
        mockMemberEventRepository.deleteMemberEventsByMemberId(memberId),
      ).called(1);
    });

    test('空のメンバーIDを処理すること', () async {
      // Arrange
      const memberId = '';

      when(mockMemberRepository.deleteMember(any)).thenAnswer((_) async {});
      when(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(any),
      ).thenAnswer((_) async {});
      when(
        mockGroupMemberRepository.deleteGroupMembersByMemberId(any),
      ).thenAnswer((_) async {});
      when(
        mockMemberEventRepository.deleteMemberEventsByMemberId(any),
      ).thenAnswer((_) async {});

      // Act
      await usecase.execute(memberId);

      // Assert
      verify(mockMemberRepository.deleteMember(memberId)).called(1);
      verify(
        mockTripParticipantRepository.deleteTripParticipantsByMemberId(
          memberId,
        ),
      ).called(1);
      verify(
        mockGroupMemberRepository.deleteGroupMembersByMemberId(memberId),
      ).called(1);
      verify(
        mockMemberEventRepository.deleteMemberEventsByMemberId(memberId),
      ).called(1);
    });
  });
}
