import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/presentation/features/trip/task_list.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(height: 600, child: child)),
  );
}

void main() {
  group('TaskList', () {
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
        name: 'チケット手配',
        isCompleted: false,
        parentTaskId: 'parent-1',
      ),
    ];

    test('親タスクだけをorderIndex順で取得できること', () {
      final target = [
        TaskDto(
          id: 'parent-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '当日',
          isCompleted: false,
        ),
        tasks[1],
        tasks[0],
      ];

      final result = parentTasks(target);

      expect(result.map((task) => task.id), ['parent-1', 'parent-2']);
    });

    test('指定した親の子タスクだけをorderIndex順で取得できること', () {
      final target = [
        TaskDto(
          id: 'child-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '荷造り',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
        TaskDto(
          id: 'other-child',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '別親の子',
          isCompleted: false,
          parentTaskId: 'parent-2',
        ),
        tasks[1],
      ];

      final result = childrenOfParent(target, 'parent-1');

      expect(result.map((task) => task.id), ['child-1', 'child-2']);
    });

    testWidgets('親子タスク一覧を表示できること', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          TaskList(
            tasks: tasks,
            collapsedParentIds: const {},
            subtitleBuilder: (_) => const [],
            onToggleCompletion: (_, __) {},
            onToggleCollapse: (_) {},
            onTapTask: (_) {},
            onDeleteTask: (_) {},
            onReorderParents: (_, __) {},
            onReorderChildren: (_, __, ___) {},
          ),
        ),
      );

      expect(find.byKey(const Key('parent_list')), findsOneWidget);
      expect(find.text('準備'), findsOneWidget);
      expect(find.byKey(const Key('child_list_parent-1')), findsOneWidget);
      expect(find.text('チケット手配'), findsOneWidget);
    });

    testWidgets('折り畳み状態に応じて子タスク表示を切り替えられること', (tester) async {
      String? toggledParentId;

      await tester.pumpWidget(
        _wrapWithApp(
          TaskList(
            tasks: tasks,
            collapsedParentIds: const {'parent-1'},
            subtitleBuilder: (_) => const [],
            onToggleCompletion: (_, __) {},
            onToggleCollapse: (parentId) {
              toggledParentId = parentId;
            },
            onTapTask: (_) {},
            onDeleteTask: (_) {},
            onReorderParents: (_, __) {},
            onReorderChildren: (_, __, ___) {},
          ),
        ),
      );

      expect(find.text('チケット手配'), findsNothing);

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(toggledParentId, 'parent-1');
    });

    testWidgets('子タスクリストのドラッグ境界が設定されていること', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          TaskList(
            tasks: tasks,
            collapsedParentIds: const {},
            subtitleBuilder: (_) => const [],
            onToggleCompletion: (_, __) {},
            onToggleCollapse: (_) {},
            onTapTask: (_) {},
            onDeleteTask: (_) {},
            onReorderParents: (_, __) {},
            onReorderChildren: (_, __, ___) {},
          ),
        ),
      );

      final childListFinder = find.byKey(const Key('child_list_parent-1'));
      expect(childListFinder, findsOneWidget);
      expect(
        find.ancestor(of: childListFinder, matching: find.byType(DragBoundary)),
        findsOneWidget,
      );

      final listView = tester.widget<ReorderableListView>(childListFinder);
      expect(listView.dragBoundaryProvider, isNotNull);
    });
  });
}
