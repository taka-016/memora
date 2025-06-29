import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/presentation/widgets/member_settings.dart';

import 'member_settings_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late MockMemberRepository mockMemberRepository;
  late Member testMember;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    testMember = Member(
      id: 'test-member-id',
      accountId: 'test-account-id',
      administratorId: null,
      nickname: 'Test User',
      kanjiLastName: '山田',
      kanjiFirstName: '太郎',
      hiraganaLastName: 'やまだ',
      hiraganaFirstName: 'たろう',
      firstName: 'Taro',
      lastName: 'Yamada',
      gender: '男性',
      birthday: DateTime(1990, 1, 1),
      email: 'test@example.com',
      phoneNumber: '090-1234-5678',
      type: 'member',
      passportNumber: null,
      passportExpiration: null,
      anaMileageNumber: null,
      jalMileageNumber: null,
    );
  });

  group('MemberSettings', () {
    testWidgets('初期化時にメンバーリストが読み込まれること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: 'managed-account-1',
          administratorId: testMember.id,
          nickname: 'Managed User 1',
          kanjiLastName: '佐藤',
          kanjiFirstName: '花子',
          hiraganaLastName: 'さとう',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Sato',
          gender: '女性',
          birthday: DateTime(1995, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-9876-5432',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
          anaMileageNumber: null,
          jalMileageNumber: null,
        ),
      ];

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedMembers);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberSettings(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      // 初期ローディング状態を確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).called(1);
      expect(find.text('メンバー設定'), findsOneWidget);
      expect(find.text('Managed User 1'), findsOneWidget);
      expect(find.text('メール: hanako@example.com'), findsOneWidget);
    });

    testWidgets('管理しているメンバーがいない場合、空状態が表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberSettings(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('管理しているメンバーがいません'), findsOneWidget);
      expect(find.text('メンバー追加ボタンから新しいメンバーを追加してください'), findsOneWidget);
    });

    testWidgets('メンバー追加ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberSettings(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('メンバー追加'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('データ読み込みエラー時にスナックバーが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberSettings(
              member: testMember,
              memberRepository: mockMemberRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('データの読み込みに失敗しました: Exception: Network error'),
        findsOneWidget,
      );
    });

    testWidgets('リフレッシュ機能が動作すること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: 'managed-account-1',
          administratorId: testMember.id,
          nickname: 'Managed User 1',
          kanjiLastName: '佐藤',
          kanjiFirstName: '花子',
          hiraganaLastName: 'さとう',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Sato',
          gender: '女性',
          birthday: DateTime(1995, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-9876-5432',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
          anaMileageNumber: null,
          jalMileageNumber: null,
        ),
      ];

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedMembers);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberSettings(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // リフレッシュ実行
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).called(2);
    });

    testWidgets('メンバー表示名が正しく表示されること', (WidgetTester tester) async {
      // Arrange
      final memberWithNickname = Member(
        id: 'member-1',
        accountId: 'account-1',
        administratorId: testMember.id,
        nickname: 'ニックネーム',
        kanjiLastName: '佐藤',
        kanjiFirstName: '花子',
        hiraganaLastName: 'さとう',
        hiraganaFirstName: 'はなこ',
        firstName: 'Hanako',
        lastName: 'Sato',
        gender: '女性',
        birthday: DateTime(1995, 5, 15),
        email: 'hanako@example.com',
        phoneNumber: '090-9876-5432',
        type: 'member',
        passportNumber: null,
        passportExpiration: null,
        anaMileageNumber: null,
        jalMileageNumber: null,
      );

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => [memberWithNickname]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberSettings(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - ニックネームが優先表示される
      expect(find.text('ニックネーム'), findsOneWidget);
    });

    testWidgets('編集ボタンと削除ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: 'managed-account-1',
          administratorId: testMember.id,
          nickname: 'Managed User 1',
          kanjiLastName: '佐藤',
          kanjiFirstName: '花子',
          hiraganaLastName: 'さとう',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Sato',
          gender: '女性',
          birthday: DateTime(1995, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-9876-5432',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
          anaMileageNumber: null,
          jalMileageNumber: null,
        ),
      ];

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedMembers);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberSettings(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
