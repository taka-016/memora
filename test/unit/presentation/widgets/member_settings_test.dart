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
      displayName: 'Test User',
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
          displayName: 'Managed User 1',
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
      expect(find.text('hanako@example.com'), findsOneWidget);
    });

    testWidgets('管理しているメンバーがいない場合でもログインユーザーが表示されること', (
      WidgetTester tester,
    ) async {
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
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget); // ログインユーザーのみ
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
          displayName: 'Managed User 1',
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

    testWidgets('メンバーの表示名が正しく表示されること', (WidgetTester tester) async {
      // Arrange
      final memberWithNickname = Member(
        id: 'member-1',
        accountId: 'account-1',
        administratorId: testMember.id,
        displayName: '表示名',
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

      // Assert - 表示名が優先表示される
      expect(find.text('表示名'), findsOneWidget);
    });

    testWidgets('編集ボタンと削除ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: 'managed-account-1',
          administratorId: testMember.id,
          displayName: 'Managed User 1',
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
      expect(find.byIcon(Icons.edit), findsNWidgets(2)); // ログインユーザー + 管理メンバー
      expect(
        find.byIcon(Icons.delete),
        findsOneWidget,
      ); // 管理メンバーのみ（ログインユーザーは非表示）
    });

    testWidgets('1行目にログインユーザーのメンバーが表示されること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: 'managed-account-1',
          administratorId: testMember.id,
          displayName: 'Managed User 1',
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
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles.length, 2); // ログインユーザー + 管理メンバー1人

      // 1行目がログインユーザー（testMember）であることを確認
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('1行目のログインユーザーメンバーは削除不可であること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: 'managed-account-1',
          administratorId: testMember.id,
          displayName: 'Managed User 1',
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
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles.length, 2);

      // 1行目（ログインユーザー）の削除ボタンが無効化されていることを確認
      final firstListTile = listTiles.first;
      final firstTrailing = firstListTile.trailing as Row;
      final firstButtons = firstTrailing.children.whereType<IconButton>();

      // 1行目に編集ボタンはある
      expect(
        firstButtons.any(
          (button) =>
              button.icon is Icon && (button.icon as Icon).icon == Icons.edit,
        ),
        true,
      );
      // 1行目に削除ボタンがない（非表示）
      expect(
        firstButtons.any(
          (button) =>
              button.icon is Icon && (button.icon as Icon).icon == Icons.delete,
        ),
        false,
      );

      // 2行目（管理メンバー）には削除ボタンがある
      final secondListTile = listTiles.last;
      final secondTrailing = secondListTile.trailing as Row;
      final secondButtons = secondTrailing.children.whereType<IconButton>();
      expect(
        secondButtons.any(
          (button) =>
              button.icon is Icon && (button.icon as Icon).icon == Icons.delete,
        ),
        true,
      );
    });
  });
}
