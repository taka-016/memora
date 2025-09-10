import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/get_member_by_id_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';

import 'get_member_by_id_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late GetMemberByIdUseCase useCase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    useCase = GetMemberByIdUseCase(mockMemberRepository);
  });

  group('GetMemberByIdUseCase', () {
    final testMember = Member(
      id: 'member123',
      accountId: 'user123',
      displayName: 'テストユーザー',
      kanjiLastName: '田中',
      kanjiFirstName: '太郎',
    );

    test('有効なIDでメンバー情報を正常に取得できる', () async {
      // Arrange
      when(
        mockMemberRepository.getMemberById('member123'),
      ).thenAnswer((_) async => testMember);

      // Act
      final result = await useCase.execute('member123');

      // Assert
      expect(result, equals(testMember));
      verify(mockMemberRepository.getMemberById('member123')).called(1);
    });

    test('存在しないIDを指定した場合、nullを返す', () async {
      // Arrange
      when(
        mockMemberRepository.getMemberById('nonexistent'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute('nonexistent');

      // Assert
      expect(result, isNull);
      verify(mockMemberRepository.getMemberById('nonexistent')).called(1);
    });

    test('空のIDを指定した場合、nullを返す', () async {
      // Arrange
      when(
        mockMemberRepository.getMemberById(''),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute('');

      // Assert
      expect(result, isNull);
      verify(mockMemberRepository.getMemberById('')).called(1);
    });
  });
}
