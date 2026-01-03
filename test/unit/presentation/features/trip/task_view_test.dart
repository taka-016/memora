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
  });
}
