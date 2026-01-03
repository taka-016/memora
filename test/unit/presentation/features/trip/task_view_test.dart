import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/presentation/features/trip/task_view.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(height: 600, child: child)),
  );
}

void main() {
  group('TaskView', () {
    final members = [
      GroupMemberDto(
        memberId: 'member-1',
        groupId: 'group-1',
        displayName: '山田太郎',
      ),
    ];

    testWidgets('タスクが表示されること', (tester) async {
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'ホテル予約',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(tasks: tasks, groupMembers: members, onChanged: (_) {}),
        ),
      );

      expect(find.text('ホテル予約'), findsOneWidget);
    });

    testWidgets('タスク追加でリストとコールバックが更新されること', (tester) async {
      List<TaskDto> lastChanged = [];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tasks: const [],
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('task_name_field')), '航空券手配');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      expect(find.text('航空券手配'), findsOneWidget);
      expect(lastChanged.length, 1);
      expect(lastChanged.first.name, '航空券手配');
    });

    testWidgets('チェックボックスで完了状態が更新されること', (tester) async {
      List<TaskDto> lastChanged = [];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '観光計画',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(lastChanged.first.isCompleted, isTrue);
    });

    testWidgets('タスクタップで編集ボトムシートが開くこと', (tester) async {
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'ホテル予約',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(tasks: tasks, groupMembers: members, onChanged: (_) {}),
        ),
      );

      await tester.tap(find.text('ホテル予約'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('task_edit_bottom_sheet')), findsOneWidget);
    });

    testWidgets('ドラッグで並び替えた順番がコールバックされること', (tester) async {
      List<TaskDto> lastChanged = [];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'ホテル予約',
          isCompleted: false,
        ),
        TaskDto(
          id: 'task-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '観光計画',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      final dragHandle = find.byIcon(Icons.drag_handle).last;
      await tester.drag(dragHandle, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(lastChanged.first.id, 'task-2');
      expect(lastChanged.first.orderIndex, 0);
      expect(lastChanged.last.id, 'task-1');
      expect(lastChanged.last.orderIndex, 1);
    });

    testWidgets('親子タスクの折り畳みが動作すること', (tester) async {
      final tasks = [
        TaskDto(
          id: 'parent',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child',
          tripId: 'trip-1',
          orderIndex: 1,
          name: 'チケット手配',
          isCompleted: false,
          parentTaskId: 'parent',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(tasks: tasks, groupMembers: members, onChanged: (_) {}),
        ),
      );

      expect(find.text('チケット手配'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();
      expect(find.text('チケット手配'), findsNothing);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      expect(find.text('チケット手配'), findsOneWidget);
    });

    testWidgets('担当者が不明な場合はIDを表示すること', (tester) async {
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'ホテル予約',
          isCompleted: false,
          assignedMemberId: 'unknown-member',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(tasks: tasks, groupMembers: members, onChanged: (_) {}),
        ),
      );

      expect(find.text('担当: unknown-member'), findsOneWidget);
    });

    testWidgets('親が存在しない子タスクは親タスクとして表示されること', (tester) async {
      final tasks = [
        TaskDto(
          id: 'orphan',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '単独タスク',
          isCompleted: false,
          parentTaskId: 'missing-parent',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(tasks: tasks, groupMembers: members, onChanged: (_) {}),
        ),
      );

      final card = tester.widget<Card>(
        find.descendant(
          of: find.byKey(const Key('task_item_orphan')),
          matching: find.byType(Card),
        ),
      );
      final margin = card.margin as EdgeInsets;

      expect(margin.left, 4);
    });

    testWidgets('子タスクがある場合は削除ボタンを表示しないこと', (tester) async {
      final tasks = [
        TaskDto(
          id: 'parent',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '手続き',
          isCompleted: false,
          parentTaskId: 'parent',
        ),
        TaskDto(
          id: 'solo',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '単独タスク',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(tasks: tasks, groupMembers: members, onChanged: (_) {}),
        ),
      );

      final parentDeleteButton = find.descendant(
        of: find.byKey(const Key('task_item_parent')),
        matching: find.byIcon(Icons.delete),
      );
      final soloDeleteButton = find.descendant(
        of: find.byKey(const Key('task_item_solo')),
        matching: find.byIcon(Icons.delete),
      );

      expect(parentDeleteButton, findsNothing);
      expect(soloDeleteButton, findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNWidgets(2));
    });

    testWidgets('親タスクのドラッグで子タスクのまとまりを保ったまま並び替えられること', (tester) async {
      List<TaskDto> lastChanged = [];
      final tasks = [
        TaskDto(
          id: 'parent-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '手続き',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
        TaskDto(
          id: 'parent-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '移動',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child-2',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'チケット購入',
          isCompleted: false,
          parentTaskId: 'parent-2',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      final dragHandle = find.byIcon(Icons.drag_handle).at(2);
      await tester.drag(dragHandle, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(lastChanged.map((task) => task.id).toList(), [
        'parent-2',
        'child-2',
        'parent-1',
        'child-1',
      ]);
      expect(lastChanged[0].orderIndex, 0);
      expect(lastChanged[1].orderIndex, 0);
      expect(lastChanged[2].orderIndex, 1);
      expect(lastChanged[3].orderIndex, 0);
    });

    testWidgets('子タスクは他の親タスクより上に移動できないこと', (tester) async {
      bool onChangedCalled = false;
      List<TaskDto>? lastChanged;
      final tasks = [
        TaskDto(
          id: 'parent-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '手続き',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
        TaskDto(
          id: 'parent-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '移動',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child-2',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'チケット購入',
          isCompleted: false,
          parentTaskId: 'parent-2',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              onChangedCalled = true;
              lastChanged = updated;
            },
          ),
        ),
      );

      final dragHandle = find.byIcon(Icons.drag_handle).at(3);
      await tester.drag(dragHandle, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(onChangedCalled, isFalse);
      expect(lastChanged, isNull);
    });
  });
}
