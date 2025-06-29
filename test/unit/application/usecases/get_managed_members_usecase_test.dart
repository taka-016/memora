import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_managed_members_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';

import 'get_managed_members_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late GetManagedMembersUsecase usecase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    usecase = GetManagedMembersUsecase(mockMemberRepository);
  });

  group('GetManagedMembersUsecase', () {
    test(
      'should return list of managed members when administrator member is provided',
      () async {
        // Arrange
        final administratorMember = Member(
          id: 'admin-member-id',
          accountId: 'admin-account-id',
          administratorId: 'admin-administrator-id',
          nickname: 'Admin',
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
            administratorId: 'admin-member-id',
            nickname: 'メンバー1',
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
            administratorId: 'admin-member-id',
            nickname: 'メンバー2',
            kanjiLastName: '佐藤',
            kanjiFirstName: '次郎',
            hiraganaLastName: 'サトウ',
            hiraganaFirstName: 'ジロウ',
            gender: 'male',
            birthday: DateTime(2000, 12, 25),
          ),
        ];

        when(
          mockMemberRepository.getMembersByAdministratorId('admin-member-id'),
        ).thenAnswer((_) async => expectedMembers);

        // Act
        final result = await usecase.execute(administratorMember);

        // Assert
        expect(result, equals(expectedMembers));
        verify(
          mockMemberRepository.getMembersByAdministratorId('admin-member-id'),
        ).called(1);
      },
    );

    test('should return empty list when no managed members exist', () async {
      // Arrange
      final administratorMember = Member(
        id: 'admin-member-id',
        accountId: 'admin-account-id',
        administratorId: 'admin-administrator-id',
        nickname: 'Admin',
        kanjiLastName: '管理',
        kanjiFirstName: '太郎',
        hiraganaLastName: 'カンリ',
        hiraganaFirstName: 'タロウ',
        gender: 'male',
        birthday: DateTime(1990, 1, 1),
      );

      when(
        mockMemberRepository.getMembersByAdministratorId('admin-member-id'),
      ).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute(administratorMember);

      // Assert
      expect(result, isEmpty);
      verify(
        mockMemberRepository.getMembersByAdministratorId('admin-member-id'),
      ).called(1);
    });
  });
}
