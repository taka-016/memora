import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'member_repository_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
  });

  group('MemberRepository accountId関連のテスト', () {
    const testAccountId = 'test-uid-12345';
    const testMemberId = 'member-id-1';

    final testMember = Member(
      id: testMemberId,
      accountId: testAccountId,
      firstName: 'テスト',
      lastName: '太郎',
      hiraganaFirstName: 'てすと',
      hiraganaLastName: 'たろう',
      birthday: DateTime(1990, 1, 1),
      gender: 'male',
      phoneNumber: '090-1234-5678',
      email: 'test@example.com',
    );

    test('accountIdでメンバーを取得できる', () async {
      // arrange
      when(
        mockMemberRepository.getMemberByAccountId(testAccountId),
      ).thenAnswer((_) async => testMember);

      // act
      final result = await mockMemberRepository.getMemberByAccountId(
        testAccountId,
      );

      // assert
      expect(result, equals(testMember));
      expect(result?.accountId, equals(testAccountId));
      verify(
        mockMemberRepository.getMemberByAccountId(testAccountId),
      ).called(1);
    });

    test('存在しないaccountIdの場合nullを返す', () async {
      // arrange
      const nonExistentAccountId = 'non-existent-uid';
      when(
        mockMemberRepository.getMemberByAccountId(nonExistentAccountId),
      ).thenAnswer((_) async => null);

      // act
      final result = await mockMemberRepository.getMemberByAccountId(
        nonExistentAccountId,
      );

      // assert
      expect(result, isNull);
      verify(
        mockMemberRepository.getMemberByAccountId(nonExistentAccountId),
      ).called(1);
    });
  });
}
