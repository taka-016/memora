import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/presentation/features/trip/task_edit_bottom_sheet.dart';

Future<void> _openBottomSheet(
  WidgetTester tester, {
  required TaskDto task,
  required List<TaskDto> tasks,
  required List<GroupMemberDto> members,
  required ValueChanged<TaskDto> onSaved,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => TaskEditBottomSheet(
                    task: task,
                    tasks: tasks,
                    groupMembers: members,
                    onSaved: onSaved,
                  ),
                );
              },
              child: const Text('開く'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
}

void main() {
  group('TaskEditBottomSheet', () {
    final members = [
      GroupMemberDto(
        memberId: 'member-1',
        groupId: 'group-1',
        displayName: '山田太郎',
      ),
      GroupMemberDto(
        memberId: 'member-2',
        groupId: 'group-1',
        displayName: '佐藤花子',
      ),
    ];

    testWidgets('初期値が表示されること', (tester) async {
      final task = TaskDto(
        id: 'task-1',
        tripId: 'trip-1',
        orderIndex: 0,
        name: 'ホテル予約',
        isCompleted: false,
        assignedMemberId: 'member-1',
      );

      await _openBottomSheet(
        tester,
        task: task,
        tasks: [task],
        members: members,
        onSaved: (_) {},
      );

      expect(find.text('ホテル予約'), findsOneWidget);
      expect(find.text('山田太郎'), findsWidgets);
      expect(find.text('担当者'), findsOneWidget);
    });

    testWidgets('担当者と親タスクが存在しない場合は未選択として扱われること', (tester) async {
      TaskDto? saved;
      final task = TaskDto(
        id: 'task-1',
        tripId: 'trip-1',
        orderIndex: 0,
        name: 'ホテル予約',
        isCompleted: false,
        assignedMemberId: 'missing-member',
        parentTaskId: 'missing-parent',
      );

      await _openBottomSheet(
        tester,
        task: task,
        tasks: [task],
        members: members,
        onSaved: (updated) {
          saved = updated;
        },
      );

      final assignedDropdown = find.byKey(
        const Key('assigned_member_dropdown'),
      );
      final parentDropdown = find.byKey(const Key('parent_task_dropdown'));
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(assignedDropdown)
            .initialValue,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(parentDropdown)
            .initialValue,
        isNull,
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.assignedMemberId, isNull);
      expect(saved!.parentTaskId, isNull);
    });

    testWidgets('保存で入力値がコールバックされること', (tester) async {
      TaskDto? saved;
      final parentTask = TaskDto(
        id: 'parent-1',
        tripId: 'trip-1',
        orderIndex: 0,
        name: '下見',
        isCompleted: false,
      );
      final editingTask = TaskDto(
        id: 'task-2',
        tripId: 'trip-1',
        orderIndex: 1,
        name: '移動手段',
        isCompleted: false,
      );

      await _openBottomSheet(
        tester,
        task: editingTask,
        tasks: [parentTask, editingTask],
        members: members,
        onSaved: (task) {
          saved = task;
        },
      );

      await tester.enterText(find.byType(TextField).first, '移動手段検討');
      await tester.tap(find.byKey(const Key('assigned_member_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('佐藤花子').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('parent_task_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下見').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.name, '移動手段検討');
      expect(saved!.assignedMemberId, 'member-2');
      expect(saved!.parentTaskId, 'parent-1');
    });

    testWidgets('タスク名未入力の場合はエラーが表示されること', (tester) async {
      var called = false;
      final task = TaskDto(
        id: 'task-1',
        tripId: 'trip-1',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );

      await _openBottomSheet(
        tester,
        task: task,
        tasks: [task],
        members: members,
        onSaved: (_) {
          called = true;
        },
      );

      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('タスク名を入力してください'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('子タスクを持つタスクは親タスクを変更できないこと', (tester) async {
      TaskDto? saved;
      final grandParent = TaskDto(
        id: 'grand-parent',
        tripId: 'trip-1',
        orderIndex: 0,
        name: '全体調整',
        isCompleted: false,
      );
      final editingTask = TaskDto(
        id: 'task-1',
        tripId: 'trip-1',
        orderIndex: 1,
        name: '下見',
        isCompleted: false,
        parentTaskId: 'grand-parent',
      );
      final childTask = TaskDto(
        id: 'task-2',
        tripId: 'trip-1',
        orderIndex: 2,
        name: 'ルート確認',
        isCompleted: false,
        parentTaskId: 'task-1',
      );

      await _openBottomSheet(
        tester,
        task: editingTask,
        tasks: [grandParent, editingTask, childTask],
        members: members,
        onSaved: (task) {
          saved = task;
        },
      );

      final parentDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String?> &&
            widget.decoration.labelText == '親タスク',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(parentDropdown)
            .onChanged,
        isNull,
      );
      expect(find.text('子タスクがあるため親タスクは変更できません'), findsOneWidget);

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.parentTaskId, 'grand-parent');
    });

    testWidgets('任意項目をクリアして保存できること', (tester) async {
      TaskDto? saved;
      final parentTask = TaskDto(
        id: 'parent-1',
        tripId: 'trip-1',
        orderIndex: 0,
        name: '下見',
        isCompleted: false,
      );
      final editingTask = TaskDto(
        id: 'task-2',
        tripId: 'trip-1',
        orderIndex: 1,
        name: '移動手段',
        isCompleted: false,
        memo: 'メモあり',
        dueDate: DateTime(2025, 1, 10),
        assignedMemberId: 'member-1',
        parentTaskId: 'parent-1',
      );

      await _openBottomSheet(
        tester,
        task: editingTask,
        tasks: [parentTask, editingTask],
        members: members,
        onSaved: (task) {
          saved = task;
        },
      );

      await tester.enterText(find.byType(TextField).first, '移動手段再検討');
      await tester.tap(find.byKey(const Key('assigned_member_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('未選択').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('parent_task_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('なし').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('締切日をクリア'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'メモ',
        ),
        '',
      );
      await tester.pump();

      final memoField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'メモ',
      );
      final memoTextField = tester.widget<TextField>(memoField);
      expect(memoTextField.controller?.text, isEmpty);

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.name, '移動手段再検討');
      expect(saved!.assignedMemberId, isNull);
      expect(saved!.parentTaskId, isNull);
      expect(saved!.dueDate, isNull);
      expect(saved!.memo, isNull);
    });

    testWidgets('キャンセルで変更が破棄されること', (tester) async {
      var called = false;
      final task = TaskDto(
        id: 'task-1',
        tripId: 'trip-1',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );

      await _openBottomSheet(
        tester,
        task: task,
        tasks: [task],
        members: members,
        onSaved: (_) {
          called = true;
        },
      );

      await tester.enterText(find.byType(TextField).first, '変更後の名前');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.byType(TaskEditBottomSheet), findsNothing);
    });
  });
}
