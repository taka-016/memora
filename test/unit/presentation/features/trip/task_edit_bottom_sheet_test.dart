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
      await tester.tap(find.text('担当者'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('佐藤花子').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('親タスク'));
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
  });
}
