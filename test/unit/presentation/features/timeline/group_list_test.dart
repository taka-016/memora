import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/shared/group_selection/group_selection_list.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  late GroupMemberDto testMemberDto;

  setUp(() {
    testMemberDto = GroupMemberDto(
      memberId: 'admin1',
      groupId: 'group1',
      displayName: 'タロちゃん',
      email: 'taro@example.com',
    );
  });

  Widget createTestWidget({
    required Future<List<GroupDto>> groupsFuture,
    VoidCallback? onRetry,
    void Function(GroupDto)? onGroupSelected,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: GroupSelectionList(
            title: 'グループを選択',
            groupsFuture: groupsFuture,
            onRetry: onRetry,
            onGroupSelected: onGroupSelected,
          ),
        ),
      ),
    );
  }

  group('GroupSelectionList', () {
    testWidgets('グループ選択タイトルと一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final member1 = GroupMemberDto(
        memberId: 'member1',
        groupId: 'group1',
        displayName: '田中',
        email: 'tanaka@example.com',
      );
      final member2 = GroupMemberDto(
        memberId: 'member2',
        groupId: 'group2',
        displayName: '佐藤',
        email: 'sato@example.com',
      );
      final groupsWithMembers = [
        GroupDto(id: '1', ownerId: 'owner1', name: 'グループ1', members: [member1]),
        GroupDto(
          id: '2',
          ownerId: 'owner2',
          name: 'グループ2',
          members: [member1, member2],
        ),
      ];

      // Act
      await tester.pumpWidget(
        createTestWidget(groupsFuture: Future.value(groupsWithMembers)),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループを選択'), findsOneWidget);
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('グループ2'), findsOneWidget);
      expect(find.text('1人のメンバー'), findsOneWidget);
      expect(find.text('2人のメンバー'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNWidgets(2));
    });

    testWidgets('グループが存在しない場合、空状態が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(groupsFuture: Future.value([])));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループがありません'), findsOneWidget);
      expect(find.text('グループを作成'), findsNothing);
    });

    testWidgets('エラーが発生した場合、エラー状態が表示される', (WidgetTester tester) async {
      // Arrange
      final failingCompleter = Completer<List<GroupDto>>();

      // Act
      await tester.pumpWidget(
        createTestWidget(groupsFuture: failingCompleter.future),
      );
      failingCompleter.completeError(TestException('エラーテスト'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });

    testWidgets('エラー状態で再読み込みボタンをタップすると、親のonRetryが呼ばれる', (
      WidgetTester tester,
    ) async {
      // Arrange
      var retried = false;
      final failingCompleter = Completer<List<GroupDto>>();

      // Act
      await tester.pumpWidget(
        createTestWidget(
          groupsFuture: failingCompleter.future,
          onRetry: () {
            retried = true;
          },
        ),
      );
      failingCompleter.completeError(TestException('エラーテスト'));
      await tester.pumpAndSettle();

      // 再読み込みボタンをタップ
      await tester.tap(find.text('再読み込み'));
      await tester.pump();

      // Assert
      expect(retried, isTrue);
      expect(find.text('エラーが発生しました'), findsOneWidget);
    });

    testWidgets('グループ行をタップしたときにコールバック関数が呼ばれる', (WidgetTester tester) async {
      // Arrange
      GroupDto? selectedGroup;
      final groupsWithMembers = [
        GroupDto(
          id: '1',
          ownerId: 'owner1',
          name: 'テストグループ',
          members: [testMemberDto],
        ),
      ];

      // Act
      await tester.pumpWidget(
        createTestWidget(
          groupsFuture: Future.value(groupsWithMembers),
          onGroupSelected: (groupWithMembers) {
            selectedGroup = groupWithMembers;
          },
        ),
      );
      await tester.pumpAndSettle();

      // グループ行をタップ
      await tester.tap(find.text('テストグループ'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedGroup, isNotNull);
      expect(selectedGroup!.id, '1');
      expect(selectedGroup!.name, 'テストグループ');
    });

    testWidgets('onRetryは新しいFutureが来るまでエラー状態を維持する', (
      WidgetTester tester,
    ) async {
      // Arrange
      var retried = false;
      final failingCompleter = Completer<List<GroupDto>>();

      // Act
      await tester.pumpWidget(
        createTestWidget(
          groupsFuture: failingCompleter.future,
          onRetry: () {
            retried = true;
          },
        ),
      );
      failingCompleter.completeError(TestException('エラーテスト'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('再読み込み'));
      await tester.pump();

      // Assert
      expect(retried, isTrue);
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('古いgroupsFutureの完了結果で新しい結果を上書きしない', (
      WidgetTester tester,
    ) async {
      // Arrange
      final firstCompleter = Completer<List<GroupDto>>();
      final secondCompleter = Completer<List<GroupDto>>();
      final oldGroups = [
        GroupDto(
          id: '1',
          ownerId: 'owner1',
          name: '古いグループ',
          members: [testMemberDto],
        ),
      ];
      final newGroups = [
        GroupDto(
          id: '2',
          ownerId: 'owner2',
          name: '新しいグループ',
          members: [testMemberDto],
        ),
      ];

      // Act
      await tester.pumpWidget(
        createTestWidget(groupsFuture: firstCompleter.future),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestWidget(groupsFuture: secondCompleter.future),
      );
      await tester.pump();

      secondCompleter.complete(newGroups);
      await tester.pumpAndSettle();

      firstCompleter.complete(oldGroups);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('新しいグループ'), findsOneWidget);
      expect(find.text('古いグループ'), findsNothing);
    });
  });
}
