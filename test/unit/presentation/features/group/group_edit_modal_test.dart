import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/features/group/group_edit_modal.dart';

void main() {
  group('GroupEditModal', () {
    testWidgets('新規作成時にタイトルが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {},
            availableMembers: const [],
          ),
        ),
      );

      expect(find.text('グループ新規作成'), findsOneWidget);
    });

    testWidgets('編集時にタイトルが正しく表示される', (WidgetTester tester) async {
      const group = Group(
        id: 'test-id',
        ownerId: 'admin-id',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: group,
            onSave: (group, selectedMemberIds) {},
            availableMembers: const [],
          ),
        ),
      );

      expect(find.text('グループ編集'), findsOneWidget);
    });

    testWidgets('必須フィールドが空の場合にバリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {},
            availableMembers: const [],
          ),
        ),
      );

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(find.text('グループ名を入力してください'), findsOneWidget);
    });

    testWidgets('有効な入力でonSaveコールバックが呼ばれる', (WidgetTester tester) async {
      Group? savedGroup;
      List<String>? savedMemberIds;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {
              savedGroup = group;
              savedMemberIds = selectedMemberIds;
            },
            availableMembers: const [],
          ),
        ),
      );

      // グループ名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テストグループ');
      await tester.pump();

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(savedGroup, isNotNull);
      expect(savedGroup!.name, 'テストグループ');
      expect(savedMemberIds, isNotNull);
    });

    testWidgets('既存メンバーが一覧表示される', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'member2',
          accountId: 'account2',
          ownerId: 'admin-id',
          displayName: 'メンバー2',
          kanjiLastName: '鈴木',
          kanjiFirstName: '花子',
          hiraganaLastName: 'すずき',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Suzuki',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-8765-4321',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {},
            availableMembers: availableMembers,
            selectedMemberIds: const ['member1', 'member2'],
          ),
        ),
      );

      expect(find.text('メンバー1'), findsOneWidget);
      expect(find.text('メンバー2'), findsOneWidget);
    });

    testWidgets('追加ボタンから未選択メンバーを追加できる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('add_member_button')));
      await tester.tap(find.byKey(const Key('add_member_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバー1').first);
      await tester.pumpAndSettle();

      expect(find.text('メンバー1'), findsOneWidget);
    });

    testWidgets('変更ボタンでメンバーを入れ替えられる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'member2',
          accountId: 'account2',
          ownerId: 'admin-id',
          displayName: 'メンバー2',
          kanjiLastName: '鈴木',
          kanjiFirstName: '花子',
          hiraganaLastName: 'すずき',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Suzuki',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-8765-4321',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {},
            availableMembers: availableMembers,
            selectedMemberIds: const ['member1'],
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('change_member_button_0')),
      );
      await tester.tap(find.byKey(const Key('change_member_button_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバー2').first);
      await tester.pumpAndSettle();

      expect(find.text('メンバー2'), findsOneWidget);
      expect(find.text('メンバー1'), findsNothing);
    });

    testWidgets('削除ボタンでメンバーを削除できる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {},
            availableMembers: availableMembers,
            selectedMemberIds: const ['member1'],
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('delete_member_button_0')),
      );
      await tester.tap(find.byKey(const Key('delete_member_button_0')));
      await tester.pump();

      expect(find.text('メンバー1'), findsNothing);
    });

    testWidgets('保存時に選択されたメンバーIDが渡される', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      List<String>? savedMemberIds;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {
              savedMemberIds = selectedMemberIds;
            },
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('add_member_button')));
      await tester.tap(find.byKey(const Key('add_member_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバー1').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'テストグループ');
      await tester.pump();

      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(savedMemberIds, ['member1']);
    });

    testWidgets('キャンセルボタンでダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => GroupEditModal(
                    onSave: (group, selectedMemberIds) {},
                    availableMembers: const [],
                  ),
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // モーダルを開く
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // モーダルが表示されることを確認
      expect(find.text('グループ新規作成'), findsOneWidget);

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // モーダルが閉じることを確認
      expect(find.text('グループ新規作成'), findsNothing);
    });

    testWidgets('メンバー数が多い場合、メンバー一覧のみスクロール可能', (WidgetTester tester) async {
      // 多数のメンバーを生成
      final availableMembers = List.generate(
        10,
        (index) => Member(
          id: 'member$index',
          accountId: 'account$index',
          ownerId: 'admin-id',
          displayName: 'メンバー$index',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'test$index@example.com',
          phoneNumber: '090-1234-567$index',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            onSave: (group, selectedMemberIds) {},
            availableMembers: availableMembers,
            selectedMemberIds: availableMembers
                .take(5)
                .map((member) => member.id)
                .toList(),
          ),
        ),
      );

      // メンバー一覧セクションが存在することを確認
      expect(find.text('メンバー一覧'), findsOneWidget);

      // メンバー一覧コンテナが存在することを確認
      expect(find.byKey(const Key('selected_member_list')), findsOneWidget);
    });

    testWidgets('既存の選択されたメンバーが正しく表示される', (WidgetTester tester) async {
      const group = Group(
        id: 'test-id',
        ownerId: 'admin-id',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'member2',
          accountId: 'account2',
          ownerId: 'admin-id',
          displayName: 'メンバー2',
          kanjiLastName: '鈴木',
          kanjiFirstName: '花子',
          hiraganaLastName: 'すずき',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Suzuki',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-8765-4321',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: group,
            onSave: (group, selectedMemberIds) {},
            availableMembers: availableMembers,
            selectedMemberIds: ['member1'], // member1が既に選択されている
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 選択済みのメンバーが一覧に表示されていることを確認
      expect(find.text('メンバー1'), findsOneWidget);
      expect(find.text('メンバー2'), findsNothing);
    });

    testWidgets('編集モードで既存グループ情報が正しく表示される', (WidgetTester tester) async {
      const group = Group(
        id: 'test-id',
        ownerId: 'admin-id',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: group,
            onSave: (group, selectedMemberIds) {},
            availableMembers: const [],
          ),
        ),
      );

      // グループ名が正しく表示されることを確認
      expect(find.text('テストグループ'), findsOneWidget);

      // メモが正しく表示されることを確認
      expect(find.text('テストメモ'), findsOneWidget);

      // 更新ボタンが表示されることを確認
      expect(find.text('更新'), findsOneWidget);
    });
  });
}
