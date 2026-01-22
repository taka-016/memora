import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';

import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/presentation/features/member/member_edit_modal.dart';

Widget _createApp({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('MemberEditModal', () {
    testWidgets('新規作成モードでタイトルが正しく表示されること', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      // Assert
      expect(find.text('メンバー新規作成'), findsOneWidget);
      expect(find.text('作成'), findsOneWidget);
    });

    testWidgets('編集モードでタイトルが正しく表示されること', (WidgetTester tester) async {
      // Arrange
      final existingMember = MemberDto(
        id: 'test-id',
        accountId: 'test-account',
        ownerId: null,
        displayName: 'テストユーザー',
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
      );

      // Act
      await tester.pumpWidget(
        _createApp(
          child: MemberEditModal(member: existingMember, onSave: (member) {}),
        ),
      );

      // Assert
      expect(find.text('メンバー編集'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('既存メンバーの情報がフォームに正しく表示されること', (WidgetTester tester) async {
      // Arrange
      final existingMember = MemberDto(
        id: 'test-id',
        accountId: 'test-account',
        ownerId: null,
        displayName: 'テストユーザー',
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
      );

      // Act
      await tester.pumpWidget(
        _createApp(
          child: MemberEditModal(member: existingMember, onSave: (member) {}),
        ),
      );

      // Assert
      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('太郎'), findsOneWidget);
      expect(find.text('やまだ'), findsOneWidget);
      expect(find.text('たろう'), findsOneWidget);
      expect(find.text('Taro'), findsOneWidget);
      expect(find.text('Yamada'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('090-1234-5678'), findsOneWidget);
      expect(find.text('1990/1/1'), findsOneWidget);
    });

    testWidgets('必須項目が未入力の場合バリデーションエラーが表示されること', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      // Act
      await tester.tap(find.text('作成'));
      await tester.pump();

      // Assert
      expect(find.text('表示名を入力してください'), findsOneWidget);
    });

    testWidgets('正しく入力された場合onSaveが呼ばれること', (WidgetTester tester) async {
      // Arrange
      Member? savedMember;

      await tester.pumpWidget(
        _createApp(
          child: MemberEditModal(
            member: null,
            onSave: (member) {
              savedMember = member;
            },
          ),
        ),
      );

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, '表示名').first,
        'テスト表示名',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '姓（漢字）').first,
        '田中',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '名（漢字）').first,
        '花子',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'メールアドレス').first,
        'hanako@example.com',
      );

      await tester.tap(find.text('作成'));
      await tester.pump();

      // Assert
      expect(savedMember, isNotNull);
      expect(savedMember!.displayName, 'テスト表示名');
      expect(savedMember!.kanjiLastName, '田中');
      expect(savedMember!.kanjiFirstName, '花子');
      expect(savedMember!.email, 'hanako@example.com');
    });

    testWidgets('性別ドロップダウンが表示されること', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      // Assert
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('性別'), findsOneWidget);
    });

    testWidgets('日付選択ボタンが正しく表示されること', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      // Assert - 日付選択エリアが表示されていることを確認
      expect(find.text('選択してください'), findsOneWidget);
      expect(find.text('生年月日'), findsOneWidget);
    });

    testWidgets('生年月日に未来日付を入力できること', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      await tester.ensureVisible(find.text('選択してください'));
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('date_header')));
      await tester.pumpAndSettle();

      final futureDate = DateTime.now().add(const Duration(days: 30));
      final inputText =
          '${futureDate.year.toString().padLeft(4, '0')}${futureDate.month.toString().padLeft(2, '0')}${futureDate.day.toString().padLeft(2, '0')}';
      await tester.enterText(find.byKey(const Key('date_field')), inputText);
      await tester.tap(find.text('確定'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('date_field')), findsNothing);
      expect(
        find.text('${futureDate.year}/${futureDate.month}/${futureDate.day}'),
        findsOneWidget,
      );
    });

    testWidgets('キャンセルボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      // Assert
      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('空文字の場合は空文字で保存されること', (WidgetTester tester) async {
      // Arrange
      Member? savedMember;

      await tester.pumpWidget(
        _createApp(
          child: MemberEditModal(
            member: null,
            onSave: (member) {
              savedMember = member;
            },
          ),
        ),
      );

      // Act - 表示名のみ入力（必須項目）
      await tester.enterText(
        find.widgetWithText(TextFormField, '表示名').first,
        'テスト表示名',
      );

      await tester.tap(find.text('作成'));
      await tester.pump();

      // Assert
      expect(savedMember, isNotNull);
      expect(savedMember!.displayName, 'テスト表示名');
      expect(savedMember!.kanjiLastName, '');
      expect(savedMember!.kanjiFirstName, '');
      expect(savedMember!.email, '');
      expect(savedMember!.phoneNumber, '');
    });

    testWidgets('フォームのスクロールが正しく動作すること', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      // Act
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      // スクロールテスト
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Assert - エラーが発生しないことを確認
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('変更後にキャンセルすると破棄確認が表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '表示名').first,
        'テスト表示名',
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('変更内容の確認'), findsOneWidget);
      expect(find.text('変更内容が保存されていません。破棄しますか？'), findsOneWidget);
    });

    testWidgets('破棄するを選択すると確認ダイアログが閉じること', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createApp(child: MemberEditModal(member: null, onSave: (member) {})),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '表示名').first,
        'テスト表示名',
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('破棄する'), findsOneWidget);
      await tester.tap(find.text('破棄する'));
      await tester.pumpAndSettle();

      expect(find.text('変更内容の確認'), findsNothing);
    });
  });
}
