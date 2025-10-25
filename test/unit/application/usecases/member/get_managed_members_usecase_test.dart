import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/domain/entities/member/member.dart';

import 'get_managed_members_usecase_test.mocks.dart';

@GenerateMocks([MemberQueryService])
void main() {
  late GetManagedMembersUsecase usecase;
  late MockMemberQueryService mockMemberQueryService;

  setUp(() {
    mockMemberQueryService = MockMemberQueryService();
    usecase = GetManagedMembersUsecase(mockMemberQueryService);
  });

  group('GetManagedMembersUsecase', () {
    test('所有者メンバーが提供された時に管理されるメンバーのリストを返すこと', () async {
      // Arrange
      final ownerMember = Member(
        id: 'admin-member-id',
        accountId: 'admin-account-id',
        ownerId: 'admin-owner-id',
        displayName: 'Admin',
        kanjiLastName: '管理',
        kanjiFirstName: '太郎',
        hiraganaLastName: 'カンリ',
        hiraganaFirstName: 'タロウ',
        gender: 'male',
        birthday: DateTime(1990, 1, 1),
      );

      final expectedMembers = [
        Member(
          id: 'member-1',
          accountId: null,
          ownerId: 'admin-member-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '花子',
          hiraganaLastName: 'タナカ',
          hiraganaFirstName: 'ハナコ',
          gender: 'female',
          birthday: DateTime(1995, 5, 10),
        ),
        Member(
          id: 'member-2',
          accountId: null,
          ownerId: 'admin-member-id',
          displayName: 'メンバー2',
          kanjiLastName: '佐藤',
          kanjiFirstName: '次郎',
          hiraganaLastName: 'サトウ',
          hiraganaFirstName: 'ジロウ',
          gender: 'male',
          birthday: DateTime(2000, 12, 25),
        ),
      ];

      when(
        mockMemberQueryService.getMembersByOwnerId(
          'admin-member-id',
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => expectedMembers);

      // Act
      final result = await usecase.execute(ownerMember);

      // Assert
      expect(result, equals(expectedMembers));
      verify(
        mockMemberQueryService.getMembersByOwnerId(
          'admin-member-id',
          orderBy: anyNamed('orderBy'),
        ),
      ).called(1);
    });

    test('管理されるメンバーが存在しない場合に空のリストを返すこと', () async {
      // Arrange
      final ownerMember = Member(
        id: 'admin-member-id',
        accountId: 'admin-account-id',
        ownerId: 'admin-owner-id',
        displayName: 'Admin',
        kanjiLastName: '管理',
        kanjiFirstName: '太郎',
        hiraganaLastName: 'カンリ',
        hiraganaFirstName: 'タロウ',
        gender: 'male',
        birthday: DateTime(1990, 1, 1),
      );

      when(
        mockMemberQueryService.getMembersByOwnerId(
          'admin-member-id',
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute(ownerMember);

      // Assert
      expect(result, isEmpty);
      verify(
        mockMemberQueryService.getMembersByOwnerId(
          'admin-member-id',
          orderBy: anyNamed('orderBy'),
        ),
      ).called(1);
    });
  });
}
