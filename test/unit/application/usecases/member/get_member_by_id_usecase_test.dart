import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/interfaces/query_services/member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/get_member_by_id_usecase.dart';
import 'package:memora/domain/entities/member.dart';

import 'get_member_by_id_usecase_test.mocks.dart';

@GenerateMocks([MemberQueryService])
void main() {
  late GetMemberByIdUseCase useCase;
  late MockMemberQueryService mockMemberQueryService;

  setUp(() {
    mockMemberQueryService = MockMemberQueryService();
    useCase = GetMemberByIdUseCase(mockMemberQueryService);
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
        mockMemberQueryService.getMemberById('member123'),
      ).thenAnswer((_) async => testMember);

      // Act
      final result = await useCase.execute('member123');

      // Assert
      expect(result, equals(testMember));
      verify(mockMemberQueryService.getMemberById('member123')).called(1);
    });

    test('存在しないIDを指定した場合、nullを返す', () async {
      // Arrange
      when(
        mockMemberQueryService.getMemberById('nonexistent'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute('nonexistent');

      // Assert
      expect(result, isNull);
      verify(mockMemberQueryService.getMemberById('nonexistent')).called(1);
    });

    test('空のIDを指定した場合、nullを返す', () async {
      // Arrange
      when(
        mockMemberQueryService.getMemberById(''),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute('');

      // Assert
      expect(result, isNull);
      verify(mockMemberQueryService.getMemberById('')).called(1);
    });
  });
}
