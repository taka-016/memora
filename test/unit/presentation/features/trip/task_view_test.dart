import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/trip/task_view.dart';
import '../../../../helpers/test_exception.dart';

class FakeTaskQueryService implements TaskQueryService {
  FakeTaskQueryService(this.tasks);

  final List<TaskDto> tasks;

  @override
  Future<List<TaskDto>> getTasksByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    return tasks;
  }
}

class FailingTaskQueryService implements TaskQueryService {
  @override
  Future<List<TaskDto>> getTasksByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) {
    throw TestException('通信エラー');
  }
}

Widget _wrapWithApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: SizedBox(height: 600, child: child)),
    ),
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
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('ホテル予約'), findsOneWidget);
    });

    testWidgets('タスク追加でリストとコールバックが更新されること', (tester) async {
      List<TaskDto> lastChanged = [];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
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
            tripId: 'trip-1',
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

    testWidgets('親タスクを完了にすると子タスクも完了になること', (tester) async {
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
          name: 'チケット手配',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final parent = lastChanged.firstWhere((task) => task.id == 'parent-1');
      final child = lastChanged.firstWhere((task) => task.id == 'child-1');

      expect(parent.isCompleted, isTrue);
      expect(child.isCompleted, isTrue);
    });

    testWidgets('親タスクを完了にすると複数の子タスク（一部完了済み）が全て完了になること', (tester) async {
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
          name: 'チケット手配',
          isCompleted: true,
          parentTaskId: 'parent-1',
        ),
        TaskDto(
          id: 'child-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: 'ホテル予約',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
        TaskDto(
          id: 'child-3',
          tripId: 'trip-1',
          orderIndex: 2,
          name: '交通手段確保',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final parent = lastChanged.firstWhere((task) => task.id == 'parent-1');
      final child1 = lastChanged.firstWhere((task) => task.id == 'child-1');
      final child2 = lastChanged.firstWhere((task) => task.id == 'child-2');
      final child3 = lastChanged.firstWhere((task) => task.id == 'child-3');

      expect(parent.isCompleted, isTrue);
      expect(child1.isCompleted, isTrue);
      expect(child2.isCompleted, isTrue);
      expect(child3.isCompleted, isTrue);
    });

    testWidgets('親タスクを完了解除しても子タスクの状態は変わらないこと', (tester) async {
      List<TaskDto> lastChanged = [];
      final tasks = [
        TaskDto(
          id: 'parent-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: true,
        ),
        TaskDto(
          id: 'child-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'チケット手配',
          isCompleted: true,
          parentTaskId: 'parent-1',
        ),
        TaskDto(
          id: 'child-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: 'ホテル予約',
          isCompleted: true,
          parentTaskId: 'parent-1',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final parent = lastChanged.firstWhere((task) => task.id == 'parent-1');
      final child1 = lastChanged.firstWhere((task) => task.id == 'child-1');
      final child2 = lastChanged.firstWhere((task) => task.id == 'child-2');

      expect(parent.isCompleted, isFalse);
      expect(child1.isCompleted, isTrue);
      expect(child2.isCompleted, isTrue);
    });

    testWidgets('子タスクを完了にしても親タスクの状態は変わらないこと', (tester) async {
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
          name: 'チケット手配',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      final parent = lastChanged.firstWhere((task) => task.id == 'parent-1');
      final child = lastChanged.firstWhere((task) => task.id == 'child-1');

      expect(parent.isCompleted, isFalse);
      expect(child.isCompleted, isTrue);
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
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('ホテル予約'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('task_edit_bottom_sheet')), findsOneWidget);
    });

    testWidgets('親タスクのドラッグで並び替えた順番がコールバックされること', (tester) async {
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
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      final dragHandle = find.byKey(const Key('parent_drag_task-2'));
      await tester.drag(dragHandle, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(lastChanged.first.id, 'task-2');
      expect(lastChanged.first.orderIndex, 0);
      expect(lastChanged.last.id, 'task-1');
      expect(lastChanged.last.orderIndex, 1);
    });

    testWidgets('子タスクは親タスク内でのみ並び替えられ、orderIndexが親タスク単位で採番されること', (
      tester,
    ) async {
      late List<TaskDto> lastChanged;
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
        TaskDto(
          id: 'child-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '荷造り',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
        TaskDto(
          id: 'parent-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '当日の流れ',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child-3',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '移動手段確認',
          isCompleted: false,
          parentTaskId: 'parent-2',
        ),
      ];
      lastChanged = List<TaskDto>.from(tasks);

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      final dragHandle = find.byKey(const Key('child_drag_child-2'));
      await tester.drag(dragHandle, const Offset(0, -300));
      await tester.pumpAndSettle();

      final updatedParent1Children = lastChanged
          .where((task) => task.parentTaskId == 'parent-1')
          .toList();
      final child3 = lastChanged.firstWhere((task) => task.id == 'child-3');

      expect(updatedParent1Children.first.id, 'child-2');
      expect(updatedParent1Children.first.orderIndex, 0);
      expect(updatedParent1Children[1].id, 'child-1');
      expect(updatedParent1Children[1].orderIndex, 1);
      expect(child3.orderIndex, 0);
    });

    testWidgets('子タスクリストのドラッグ境界が設定されていること', (tester) async {
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

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
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

    testWidgets('子タスクの有無で親タスク名の位置がずれないこと', (tester) async {
      final tasks = [
        TaskDto(
          id: 'parent-with-child',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '子タスクありの親',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child-of-parent',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '子タスク',
          isCompleted: false,
          parentTaskId: 'parent-with-child',
        ),
        TaskDto(
          id: 'parent-without-child',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '子タスクなしの親',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      final withChildOffset = tester.getTopLeft(find.text('子タスクありの親'));
      final withoutChildOffset = tester.getTopLeft(find.text('子タスクなしの親'));

      expect(withChildOffset.dx, equals(withoutChildOffset.dx));
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
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
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

    testWidgets('子タスク削除後に親タスクを削除できること', (tester) async {
      List<TaskDto> lastChanged = [];
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
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('delete_task_child')).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_task_parent')).first);
      await tester.pumpAndSettle();

      expect(find.text('チケット手配'), findsNothing);
      expect(find.text('準備'), findsNothing);
      expect(lastChanged, isEmpty);
    });

    testWidgets('子タスクを持つ親タスクには削除ボタンが表示されないこと', (tester) async {
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
          name: 'チケット手配',
          isCompleted: false,
          parentTaskId: 'parent',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('delete_task_parent')), findsNothing);
    });

    testWidgets('チェックボックスとタスク名の間隔が詰められていること', (tester) async {
      final tasks = [
        TaskDto(
          id: 'spacing-parent',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'スペース確認タスク',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      final parentCard = find.byKey(const Key('parent_item_spacing-parent'));
      final checkboxFinder = find.descendant(
        of: parentCard,
        matching: find.byType(Checkbox),
      );
      final textFinder = find.text('スペース確認タスク');

      final checkboxRect = tester.getRect(checkboxFinder);
      final textRect = tester.getRect(textFinder);
      final gap = textRect.left - checkboxRect.right;

      expect(gap, lessThanOrEqualTo(12));
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
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('担当: unknown-member'), findsOneWidget);
    });

    testWidgets('孤立した子タスクが親タスクとして表示されること', (tester) async {
      List<TaskDto> lastChanged = [];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '親タスク',
          isCompleted: false,
        ),
        TaskDto(
          id: 'task-2',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '孤立した子タスク',
          isCompleted: false,
          parentTaskId: 'non-existent-parent',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (changed) {
              lastChanged = changed;
            },
          ),
        ),
      );

      // 孤立した子タスクが親タスクとして表示される
      expect(find.text('孤立した子タスク'), findsOneWidget);

      // チェックボックスをタップしてonChangedをトリガー
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // onChangedで渡されるリストでは、孤立した子タスクのparentTaskIdがnullになっている
      expect(lastChanged.length, 2);
      final orphanTask = lastChanged.firstWhere((t) => t.id == 'task-2');
      expect(orphanTask.parentTaskId, isNull);
      expect(orphanTask.name, '孤立した子タスク');
    });

    testWidgets('コピーでペーストが有効になること', (tester) async {
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      final pasteButtonFinder = find.byKey(const Key('task_paste_button'));
      IconButton pasteButton = tester.widget(pasteButtonFinder);
      expect(pasteButton.onPressed, isNull);

      await tester.tap(find.byKey(const Key('task_copy_button')));
      await tester.pump();

      pasteButton = tester.widget(pasteButtonFinder);
      expect(pasteButton.onPressed, isNotNull);
    });

    testWidgets('新規旅行ではコピーアイコンが使用不可であること', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: null,
            tasks: const [],
            groupMembers: members,
            onChanged: (_) {},
          ),
        ),
      );

      final copyButton = tester.widget<IconButton>(
        find.byKey(const Key('task_copy_button')),
      );

      expect(copyButton.onPressed, isNull);
    });

    testWidgets('ペーストでタスクが置き換わること', (tester) async {
      List<TaskDto> lastChanged = [];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '元のタスク',
          isCompleted: false,
        ),
      ];
      final copiedTasks = [
        TaskDto(
          id: 'copied-task',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'コピー済みタスク',
          isCompleted: false,
        ),
      ];
      final fakeQueryService = FakeTaskQueryService(copiedTasks);

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
          overrides: [
            taskQueryServiceProvider.overrideWithValue(fakeQueryService),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('task_copy_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('task_paste_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task_paste_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('元のタスク'), findsNothing);
      expect(find.text('コピー済みタスク'), findsOneWidget);
      expect(lastChanged.length, 1);
      expect(lastChanged.first.name, 'コピー済みタスク');
    });

    testWidgets('ペースト確認ダイアログのキャンセルでタスクが変更されないこと', (tester) async {
      List<TaskDto> lastChanged = [];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '元のタスク',
          isCompleted: false,
        ),
      ];
      final copiedTasks = [
        TaskDto(
          id: 'copied-task',
          tripId: 'trip-1',
          orderIndex: 0,
          name: 'コピー済みタスク',
          isCompleted: false,
        ),
      ];
      final fakeQueryService = FakeTaskQueryService(copiedTasks);

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
          overrides: [
            taskQueryServiceProvider.overrideWithValue(fakeQueryService),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('task_copy_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('task_paste_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('元のタスク'), findsOneWidget);
      expect(find.text('コピー済みタスク'), findsNothing);
      expect(lastChanged, isEmpty);
    });

    testWidgets('ペースト時に失敗するとエラーメッセージが表示されること', (tester) async {
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '元のタスク',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-1',
            tasks: tasks,
            groupMembers: members,
            onChanged: (_) {},
          ),
          overrides: [
            taskQueryServiceProvider.overrideWithValue(
              FailingTaskQueryService(),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('task_copy_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('task_paste_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task_paste_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('タスクの取得に失敗しました'), findsOneWidget);
    });

    testWidgets('ペースト時にIDと親子関係が再生成されること', (tester) async {
      List<TaskDto> lastChanged = [];
      final copiedTasks = [
        TaskDto(
          id: 'parent-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '親タスク',
          isCompleted: false,
        ),
        TaskDto(
          id: 'child-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '子タスク',
          isCompleted: false,
          parentTaskId: 'parent-1',
        ),
      ];
      final fakeQueryService = FakeTaskQueryService(copiedTasks);

      await tester.pumpWidget(
        _wrapWithApp(
          TaskView(
            tripId: 'trip-2',
            tasks: const [],
            groupMembers: members,
            onChanged: (updated) {
              lastChanged = updated;
            },
          ),
          overrides: [
            taskQueryServiceProvider.overrideWithValue(fakeQueryService),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('task_copy_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('task_paste_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task_paste_confirm_button')));
      await tester.pumpAndSettle();

      final parent = lastChanged.firstWhere((task) => task.name == '親タスク');
      final child = lastChanged.firstWhere((task) => task.name == '子タスク');

      expect(parent.id, isNot('parent-1'));
      expect(child.id, isNot('child-1'));
      expect(parent.tripId, 'trip-2');
      expect(child.tripId, 'trip-2');
      expect(child.parentTaskId, parent.id);
    });
  });
}
