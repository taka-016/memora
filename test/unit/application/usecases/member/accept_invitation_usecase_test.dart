import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'accept_invitation_usecase_test.mocks.dart';

@GenerateMocks([
  MemberInvitationQueryService,
  MemberInvitationRepository,
  MemberQueryService,
])
void main() {
  late MockMemberInvitationQueryService query;
  late MockMemberInvitationRepository repository;
  late MockMemberQueryService members;
  late AcceptInvitationUseCase usecase;
  final now = DateTime.utc(2026, 10, 18, 12);
  const invitation = MemberInvitationDto(
    id: 'i',
    inviteeId: 'm',
    inviterId: 'owner',
    invitationCode: 'code',
    version: 2,
  );
  const other = MemberInvitationDto(
    id: 'j',
    inviteeId: 'm',
    inviterId: 'owner',
    invitationCode: 'other',
    version: 4,
  );
  setUp(() {
    query = MockMemberInvitationQueryService();
    repository = MockMemberInvitationRepository();
    members = MockMemberQueryService();
    usecase = AcceptInvitationUseCase(
      query,
      repository,
      members,
      FixedAppClock(now),
    );
    when(query.getByInvitationCode('code')).thenAnswer((_) async => invitation);
    when(query.getByInvitationCode('other')).thenAnswer((_) async => other);
    when(query.getAllByInviteeId('m'))
        .thenAnswer((_) async => [invitation, other]);
    when(members.getMemberById('m')).thenAnswer(
      (_) async => const MemberDto(
        id: 'm',
        displayName: '本人',
        accountId: 'old',
        version: 7,
      ),
    );
  });
  for (final code in ['code', 'other']) {
    test('招待$codeから既存アカウントを含め同じ対象の全招待を一括承認する', () async {
      expect(await usecase.execute(code, 'user'), isTrue);
      final args = verify(repository.acceptInvitation(captureAny, captureAny))
          .captured;
      expect((args[0] as Member).accountId, 'user');
      expect((args[0] as Member).version, 7);
      expect(
        (args[1] as List<MemberInvitation>).map((i) => '${i.id}:${i.version}'),
        ['i:2', 'j:4'],
      );
      verifyNever(
        repository.deleteMemberInvitation(
          any,
          expectedVersion: anyNamed('expectedVersion'),
        ),
      );
    });
  }
  for (final absent in ['コード', 'メンバー', '承認対象', '再発行']) {
    test('$absentの欠落・変更時は承認しない', () async {
      switch (absent) {
        case 'コード':
          when(query.getByInvitationCode('code')).thenAnswer((_) async => null);
        case 'メンバー':
          when(members.getMemberById('m')).thenAnswer((_) async => null);
        case '承認対象':
          when(query.getAllByInviteeId('m')).thenAnswer((_) async => [other]);
        case '再発行':
          when(
            query.getAllByInviteeId('m'),
          ).thenAnswer((_) async => [invitation.copyWith(version: 3), other]);
      }
      expect(await usecase.execute('code', 'user'), isFalse);
      verifyNever(repository.acceptInvitation(any, any));
    });
  }
  for (final reissued in [false, true]) {
    for (final age in [
      const Duration(hours: 24),
      const Duration(hours: 24, seconds: 1),
    ]) {
      test('有効期限は${reissued ? '再発行' : '発行'}から$ageで判定する', () async {
        final issued = now.subtract(age);
        final value = invitation.copyWith(
          createdAt: reissued
              ? issued.subtract(const Duration(days: 2))
              : issued,
          updatedAt: reissued ? issued : null,
        );
        when(query.getByInvitationCode('code')).thenAnswer((_) async => value);
        expect(
          await usecase.execute('code', 'user'),
          age == const Duration(hours: 24),
        );
      });
    }
  }
  for (final failAt in ['一覧', '保存']) {
    test('$failAtの失敗を承認成功にしない', () async {
      if (failAt == '一覧') {
        when(query.getAllByInviteeId('m')).thenThrow(TestException());
      } else {
        when(repository.acceptInvitation(any, any)).thenThrow(TestException());
      }
      expect(await usecase.execute('code', 'user'), isFalse);
    });
  }
}
