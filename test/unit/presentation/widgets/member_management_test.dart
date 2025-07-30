import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/presentation/widgets/member_management.dart';

import 'member_management_test.mocks.dart';

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

    // 共通的なモック設定: getMemberByIdはデフォルトでtestMemberを返す
    when(
      mockMemberRepository.getMemberById(testMember.id),
    ).thenAnswer((_) async => testMember);
  });

  group('MemberManagement', () {
    testWidgets('初期化時にメンバーリストが読み込まれること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: null,
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
          home: MemberManagement(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      // 初期ローディング状態を確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // Assert - データ取得の確認
      verify(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).called(1);
      expect(find.text('メンバー管理'), findsOneWidget);

      // メンバー表示の確認
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles.length, 2); // ログインユーザー + 管理メンバー1人

      // 1行目（ログインユーザー）の確認
      final firstCard = find.byType(Card).first;
      expect(
        find.descendant(of: firstCard, matching: find.text('Test User')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: firstCard, matching: find.text('test@example.com')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: firstCard, matching: find.byIcon(Icons.delete)),
        findsNothing,
      );

      // 2行目（管理メンバー）の確認
      final secondCard = find.byType(Card).last;
      expect(
        find.descendant(of: secondCard, matching: find.text('Managed User 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: secondCard,
          matching: find.text('hanako@example.com'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: secondCard, matching: find.byIcon(Icons.delete)),
        findsOneWidget,
      );
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
          home: MemberManagement(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('メンバー追加ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberManagement(
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
            body: MemberManagement(
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
          accountId: null,
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
          home: MemberManagement(
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

    testWidgets('行タップで編集画面に遷移すること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: null,
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
          home: MemberManagement(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // タップ前は編集モーダルが表示されていないことを確認
      expect(find.text('メンバー編集'), findsNothing);

      // 管理メンバーの行をタップ（2番目のListTile）
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pump();

      // 編集モーダルが開いていることを確認
      expect(find.text('メンバー編集'), findsOneWidget);
    });

    testWidgets('メンバー情報の更新ができること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: null,
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

      when(mockMemberRepository.updateMember(any)).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberManagement(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 管理メンバーの行をタップして編集モーダルを開く（2番目のListTile）
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();

      // 表示名を変更
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Managed User 1'),
        'Updated Member Name',
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Assert - 更新処理が呼ばれることを確認
      verify(mockMemberRepository.updateMember(any)).called(1);
    });

    testWidgets('ログインユーザーメンバーの取得に失敗した場合、エラーが表示されること', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => []);

      when(
        mockMemberRepository.getMemberById(testMember.id),
      ).thenAnswer((_) async => null); // nullを返すように設定

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberManagement(
              member: testMember,
              memberRepository: mockMemberRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('データの読み込みに失敗しました: Exception: ログインユーザーメンバーの最新情報の取得に失敗しました'),
        findsOneWidget,
      );
    });

    testWidgets('accountIdを持つメンバーは削除ボタンが表示されないこと', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        // accountIdを持つメンバー（削除ボタンが表示されない）
        Member(
          id: 'managed-member-1',
          accountId: 'account-id-1',
          administratorId: testMember.id,
          displayName: 'Account Linked Member',
        ),
        // accountIdを持たないメンバー（削除ボタンが表示される）
        Member(
          id: 'managed-member-2',
          accountId: null,
          administratorId: testMember.id,
          displayName: 'Regular Member',
        ),
      ];

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedMembers);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberManagement(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(3)); // ログインユーザー + 管理メンバー2人

      // 1行目（ログインユーザー）- accountIdありなので削除ボタンなし
      final firstCard = cards.at(0);
      expect(
        find.descendant(of: firstCard, matching: find.byIcon(Icons.delete)),
        findsNothing,
      );

      // 2行目（accountIdありのメンバー）- 削除ボタンなし
      final secondCard = cards.at(1);
      expect(
        find.descendant(
          of: secondCard,
          matching: find.text('Account Linked Member'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: secondCard, matching: find.byIcon(Icons.delete)),
        findsNothing,
      );

      // 3行目（accountIdなしのメンバー）- 削除ボタンあり
      final thirdCard = cards.at(2);
      expect(
        find.descendant(of: thirdCard, matching: find.text('Regular Member')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: thirdCard, matching: find.byIcon(Icons.delete)),
        findsOneWidget,
      );
    });

    testWidgets('1行目のログインユーザーメンバーを編集後にDBから再取得されること', (
      WidgetTester tester,
    ) async {
      // Arrange
      final managedMembers = [
        Member(
          id: 'managed-member-1',
          accountId: null,
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

      // 更新後のログインユーザーメンバー
      final updatedTestMember = Member(
        id: testMember.id,
        accountId: testMember.accountId,
        administratorId: testMember.administratorId,
        displayName: '更新されたユーザー',
        kanjiLastName: '更新',
        kanjiFirstName: '太郎',
        hiraganaLastName: 'こうしん',
        hiraganaFirstName: 'たろう',
        firstName: 'Updated',
        lastName: 'User',
        gender: testMember.gender,
        birthday: testMember.birthday,
        email: testMember.email,
        phoneNumber: testMember.phoneNumber,
        type: testMember.type,
        passportNumber: testMember.passportNumber,
        passportExpiration: testMember.passportExpiration,
        anaMileageNumber: testMember.anaMileageNumber,
        jalMileageNumber: testMember.jalMileageNumber,
      );

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedMembers);

      when(mockMemberRepository.updateMember(any)).thenAnswer((_) async {});

      // 初期ロード時は元のメンバー情報を返し、更新後は更新されたメンバー情報を返す
      var callCount = 0;
      when(mockMemberRepository.getMemberById(testMember.id)).thenAnswer((
        _,
      ) async {
        callCount++;
        if (callCount == 1) {
          return testMember;
        } else {
          return updatedTestMember;
        }
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MemberManagement(
            member: testMember,
            memberRepository: mockMemberRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 初期状態では元の表示名が表示されること
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('更新されたユーザー'), findsNothing);

      // 1行目のログインユーザーメンバーの行をタップ（編集）
      await tester.tap(find.byType(ListTile).at(0));
      await tester.pump();

      // 編集モーダルが開いていることを確認
      expect(find.text('メンバー編集'), findsOneWidget);

      // 編集モーダルで更新ボタンをタップ（実際の編集内容は割愛）
      await tester.tap(find.text('更新'));
      await tester.pump();

      // 編集後の更新処理が完了するまで待機
      await tester.pumpAndSettle();

      // Assert - メンバー更新が実行されること
      verify(mockMemberRepository.updateMember(any)).called(1);

      // DBから最新情報を再取得していることを確認（初期ロード時 + 編集後のリロード時）
      verify(mockMemberRepository.getMemberById(testMember.id)).called(2);

      // 更新後のメンバー情報が表示されること
      expect(find.text('更新されたユーザー'), findsOneWidget);
      expect(find.text('Test User'), findsNothing);
    });
  });
}
