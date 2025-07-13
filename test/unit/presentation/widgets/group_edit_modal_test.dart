import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/group_edit_modal.dart';

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
        administratorId: 'admin-id',
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

    testWidgets('利用可能なメンバーが表示される', (WidgetTester tester) async {
      const availableMembers = [
        Member(
          id: 'member1',
          administratorId: 'admin-id',
          displayName: 'メンバー1',
        ),
        Member(
          id: 'member2',
          administratorId: 'admin-id',
          displayName: 'メンバー2',
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

      expect(find.text('メンバー1'), findsOneWidget);
      expect(find.text('メンバー2'), findsOneWidget);
    });

    testWidgets('メンバーを選択できる', (WidgetTester tester) async {
      const availableMembers = [
        Member(
          id: 'member1',
          administratorId: 'admin-id',
          displayName: 'メンバー1',
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

      // メンバーのチェックボックスをタップ
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      // グループ名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テストグループ');
      await tester.pump();

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(savedMemberIds, contains('member1'));
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
  });
}
