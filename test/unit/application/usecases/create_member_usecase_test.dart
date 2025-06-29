import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/create_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';

import 'create_member_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late CreateMemberUsecase usecase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    usecase = CreateMemberUsecase(mockMemberRepository);
  });

  group('CreateMemberUsecase', () {
    test('should create a new member with administrator ID set', () async {
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

      final newMemberData = Member(
        id: 'new-member-id',
        nickname: '新メンバー',
        kanjiLastName: '新田',
        kanjiFirstName: '三郎',
        hiraganaLastName: 'ニッタ',
        hiraganaFirstName: 'サブロウ',
        gender: 'male',
        birthday: DateTime(2005, 3, 15),
      );

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(administratorMember, newMemberData);

      // Assert
      final captured = verify(
        mockMemberRepository.saveMember(captureAny),
      ).captured;
      final savedMember = captured.first as Member;

      expect(savedMember.administratorId, equals('admin-member-id'));
      expect(savedMember.nickname, equals('新メンバー'));
      expect(savedMember.kanjiLastName, equals('新田'));
      expect(savedMember.kanjiFirstName, equals('三郎'));
      expect(savedMember.hiraganaLastName, equals('ニッタ'));
      expect(savedMember.hiraganaFirstName, equals('サブロウ'));
      expect(savedMember.gender, equals('male'));
      expect(savedMember.birthday, equals(DateTime(2005, 3, 15)));
    });

    test('should create member with minimal data', () async {
      // Arrange
      final administratorMember = Member(
        id: 'admin-member-id',
        accountId: 'admin-account-id',
        administratorId: 'admin-administrator-id',
        nickname: 'Admin',
      );

      final newMemberData = Member(id: 'new-member-id', nickname: 'ミニマル');

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      await usecase.execute(administratorMember, newMemberData);

      // Assert
      final captured = verify(
        mockMemberRepository.saveMember(captureAny),
      ).captured;
      final savedMember = captured.first as Member;

      expect(savedMember.administratorId, equals('admin-member-id'));
      expect(savedMember.nickname, equals('ミニマル'));
    });
  });
}
