import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/presentation/features/trip/task_view.dart';

void main() {
  group('TaskView', () {
    testWidgets('タスク一覧がorderIndex順に表示され、各情報が表示されること', (
      WidgetTester tester,
    ) async {
      final tasks = [
        EditableTask(
          id: 'task-2',
          task: Task(
            tripId: 'trip-1',
            orderIndex: 1,
            name: '資料作成',
            isCompleted: false,
            dueDate: DateTime(2024, 5, 20, 10, 0),
            memo: 'メモ内容',
            assignedMemberId: 'member-1',
          ),
        ),
        EditableTask(
          id: 'task-1',
          task: Task(
            tripId: 'trip-1',
            orderIndex: 0,
            name: '予約確認',
            isCompleted: true,
            dueDate: DateTime(2024, 5, 18, 9, 30),
            assignedMemberId: 'member-2',
          ),
        ),
      ];

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

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaskView(
                tripId: 'trip-1',
                tasks: tasks,
                assignableMembers: members,
                onChanged: (_) {},
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('予約確認'), findsOneWidget);
      expect(find.text('資料作成'), findsOneWidget);
      expect(find.textContaining('2024/05/18 09:30'), findsOneWidget);
      expect(find.textContaining('2024/05/20 10:00'), findsOneWidget);
      expect(find.textContaining('担当: 佐藤花子'), findsOneWidget);
      expect(find.textContaining('担当: 山田太郎'), findsOneWidget);
      expect(find.text('メモあり'), findsOneWidget);

      final reorderable = find.byKey(const Key('task_reorderable_list'));
      expect(reorderable, findsOneWidget);
    });

    testWidgets('並び替え時にorderIndexが再採番されてコールバックに反映されること', (
      WidgetTester tester,
    ) async {
      final tasks = [
        EditableTask(
          id: 'task-1',
          task: Task(
            tripId: 'trip-1',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ),
        EditableTask(
          id: 'task-2',
          task: Task(
            tripId: 'trip-1',
            orderIndex: 1,
            name: '予約',
            isCompleted: false,
          ),
        ),
      ];

      List<EditableTask>? updatedTasks;
      final testHandle = TaskViewTestHandle();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaskView(
                tripId: 'trip-1',
                tasks: tasks,
                onChanged: (value) => updatedTasks = value,
                onClose: () {},
                testHandle: testHandle,
              ),
            ),
          ),
        ),
      );

      testHandle.reorderForTest(0, 2);
      await tester.pumpAndSettle();

      expect(updatedTasks, isNotNull);
      expect(updatedTasks!.first.task.name, '予約');
      expect(updatedTasks!.first.task.orderIndex, 0);
      expect(updatedTasks![1].task.name, '準備');
      expect(updatedTasks![1].task.orderIndex, 1);
    });

    testWidgets('タスク追加フォームで新規タスクを登録しコールバックが呼ばれること', (
      WidgetTester tester,
    ) async {
      final tasks = [
        EditableTask(
          id: 'task-1',
          task: Task(
            tripId: 'trip-1',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ),
      ];

      List<EditableTask>? updatedTasks;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaskView(
                tripId: 'trip-1',
                tasks: tasks,
                onChanged: (value) => updatedTasks = value,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('タスク追加'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('task_name_field')),
        'チェックイン',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(updatedTasks, isNotNull);
      expect(updatedTasks!.any((task) => task.task.name == 'チェックイン'), isTrue);
      expect(updatedTasks!.last.task.orderIndex, 1);
    });

    testWidgets('完了チェックの切り替えがコールバックに反映されること', (WidgetTester tester) async {
      final tasks = [
        EditableTask(
          id: 'task-1',
          task: Task(
            tripId: 'trip-1',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ),
      ];

      List<EditableTask>? updatedTasks;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaskView(
                tripId: 'trip-1',
                tasks: tasks,
                onChanged: (value) => updatedTasks = value,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(updatedTasks, isNotNull);
      expect(updatedTasks!.first.task.isCompleted, isTrue);
    });
  });
}
