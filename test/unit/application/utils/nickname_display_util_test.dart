import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/utils/nickname_display_util.dart';
import 'package:memora/domain/entities/member.dart';

void main() {
  group('NicknameDisplayUtil', () {
    group('getDisplayName', () {
      test('ニックネームが設定されている場合、ニックネームを返す', () {
        // Arrange
        final member = Member(
          id: 'member123',
          nickname: 'テストユーザー',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
        );

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('テストユーザー'));
      });

      test('ニックネームが未設定で漢字姓名が設定されている場合、漢字姓名を返す', () {
        // Arrange
        final member = Member(
          id: 'member123',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
        );

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('田中 太郎'));
      });

      test('ニックネームが空文字で漢字姓名が設定されている場合、漢字姓名を返す', () {
        // Arrange
        final member = Member(
          id: 'member123',
          nickname: '',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
        );

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('田中 太郎'));
      });

      test('ニックネームとkanjiLastNameが未設定で、kanjiFirstNameのみ設定されている場合、漢字姓名を返す', () {
        // Arrange
        final member = Member(id: 'member123', kanjiFirstName: '太郎');

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('太郎'));
      });

      test('ニックネームとkanjiFirstNameが未設定で、kanjiLastNameのみ設定されている場合、漢字姓名を返す', () {
        // Arrange
        final member = Member(id: 'member123', kanjiLastName: '田中');

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('田中'));
      });

      test('ニックネーム、kanjiLastName、kanjiFirstNameが全て未設定の場合、名前未設定を返す', () {
        // Arrange
        final member = Member(id: 'member123');

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('名前未設定'));
      });

      test('ニックネーム、kanjiLastName、kanjiFirstNameが全て空文字の場合、名前未設定を返す', () {
        // Arrange
        final member = Member(
          id: 'member123',
          nickname: '',
          kanjiLastName: '',
          kanjiFirstName: '',
        );

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('名前未設定'));
      });

      test('ニックネームが空白文字のみの場合、漢字姓名を返す', () {
        // Arrange
        final member = Member(
          id: 'member123',
          nickname: '   ',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
        );

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('田中 太郎'));
      });

      test('漢字姓名が空白文字のみの場合、名前未設定を返す', () {
        // Arrange
        final member = Member(
          id: 'member123',
          kanjiLastName: '   ',
          kanjiFirstName: '   ',
        );

        // Act
        final result = NicknameDisplayUtil.getDisplayName(member);

        // Assert
        expect(result, equals('名前未設定'));
      });
    });
  });
}
