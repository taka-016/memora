import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';

import 'accept_invitation_usecase_test.mocks.dart';

@GenerateMocks([
  MemberInvitationQueryService,
  MemberInvitationRepository,
  MemberRepository,
  MemberQueryService,
])
void main() {
  late AcceptInvitationUseCase useCase;
  late MockMemberInvitationQueryService mockMemberInvitationQueryService;
  late MockMemberInvitationRepository mockMemberInvitationRepository;
  late MockMemberRepository mockMemberRepository;
  late MockMemberQueryService mockMemberQueryService;

  setUp(() {
    mockMemberInvitationQueryService = MockMemberInvitationQueryService();
    mockMemberInvitationRepository = MockMemberInvitationRepository();
    mockMemberRepository = MockMemberRepository();
    mockMemberQueryService = MockMemberQueryService();
    useCase = AcceptInvitationUseCase(
      mockMemberInvitationQueryService,
      mockMemberInvitationRepository,
      mockMemberRepository,
      mockMemberQueryService,
    );
  });

  group('AcceptInvitationUseCase', () {
    test('招待コードが存在し、メンバーのaccountIdを更新成功した場合trueを返す', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
      const userId = 'user-id';
      const memberInvitation = MemberInvitationDto(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
      );
      const member = MemberDto(id: 'invitee-id', displayName: 'Invitee User');
      final updatedMember = Member(
        id: 'invitee-id',
        displayName: 'Invitee User',
        accountId: userId,
      );

      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberQueryService.getMemberById('invitee-id'),
      ).thenAnswer((_) async => member);
      when(
        mockMemberRepository.updateMember(updatedMember),
      ).thenAnswer((_) async {});
      when(
        mockMemberInvitationRepository.deleteMemberInvitation('invitation-id'),
      ).thenAnswer((_) async {});

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isTrue);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberQueryService.getMemberById('invitee-id')).called(1);
      verify(mockMemberRepository.updateMember(updatedMember)).called(1);
      verify(
        mockMemberInvitationRepository.deleteMemberInvitation('invitation-id'),
      ).called(1);
    });

    test('招待コードが存在しない場合falseを返す', () async {
      // Arrange
      const invitationCode = 'invalid-code';
      const userId = 'user-id';
      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verifyNever(mockMemberQueryService.getMemberById(any));
      verifyNever(mockMemberRepository.saveMember(any));
      verifyNever(
        mockMemberInvitationRepository.deleteMemberInvitation('invitation-id'),
      );
    });

    test('メンバーが見つからない場合falseを返す', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
      const userId = 'user-id';
      const memberInvitation = MemberInvitationDto(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
      );

      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberQueryService.getMemberById('invitee-id'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberQueryService.getMemberById('invitee-id')).called(1);
      verifyNever(mockMemberRepository.saveMember(any));
      verifyNever(
        mockMemberInvitationRepository.deleteMemberInvitation('invitation-id'),
      );
    });

    test('招待対象メンバーにaccountIdが既に存在する場合でも更新する', () async {
      // Arrange
      const invitationCode = 'test-invitation-code';
      const userId = 'user-id';
      const memberInvitation = MemberInvitationDto(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
      );
      const member = MemberDto(
        id: 'invitee-id',
        displayName: 'Invitee User',
        accountId: 'existing-account-id',
      );
      final updatedMember = Member(
        id: 'invitee-id',
        displayName: 'Invitee User',
        accountId: userId,
      );

      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);
      when(
        mockMemberQueryService.getMemberById('invitee-id'),
      ).thenAnswer((_) async => member);
      when(
        mockMemberRepository.updateMember(updatedMember),
      ).thenAnswer((_) async {});
      when(
        mockMemberInvitationRepository.deleteMemberInvitation('invitation-id'),
      ).thenAnswer((_) async {});

      // Act
      final result = await useCase.execute(invitationCode, userId);

      // Assert
      expect(result, isTrue);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verify(mockMemberQueryService.getMemberById('invitee-id')).called(1);
      verify(mockMemberRepository.updateMember(updatedMember)).called(1);
      verify(
        mockMemberInvitationRepository.deleteMemberInvitation('invitation-id'),
      ).called(1);
    });

    test('招待コード作成から24時間を超えている場合falseを返しメンバーを更新しない', () async {
      // Arrange
      const invitationCode = 'expired-invitation-code';
      const userId = 'user-id';
      final memberInvitation = MemberInvitationDto(
        id: 'invitation-id',
        inviteeId: 'invitee-id',
        inviterId: 'inviter-id',
        invitationCode: invitationCode,
        createdAt: DateTime.utc(2024, 1, 1),
      );

      when(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).thenAnswer((_) async => memberInvitation);

      // Act
      final result = await useCase.execute(
        invitationCode,
        userId,
        now: DateTime.utc(2024, 1, 2, 0, 0, 1),
      );

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberInvitationQueryService.getByInvitationCode(invitationCode),
      ).called(1);
      verifyNever(mockMemberQueryService.getMemberById(any));
      verifyNever(mockMemberRepository.updateMember(any));
      verifyNever(
        mockMemberInvitationRepository.deleteMemberInvitation('invitation-id'),
      );
    });
  });
}
