import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/group_timeline.dart';

import 'group_timeline_test.mocks.dart';

@GenerateMocks([GetGroupsWithMembersUsecase])
void main() {
  group('GroupTimeline', () {
    late MockGetGroupsWithMembersUsecase mockGetGroupsWithMembersUsecase;
    late Member testMember;
    late Group testGroup;
    late List<GroupWithMembers> testGroups;

    setUp(() {
      mockGetGroupsWithMembersUsecase = MockGetGroupsWithMembersUsecase();
      testMember = const Member(
        id: 'member1',
        accountId: 'account1',
        administratorId: 'admin1',
        displayName: 'テストメンバー',
        kanjiLastName: '佐藤',
        kanjiFirstName: '太郎',
        email: 'test@example.com',
      );
      testGroup = const Group(
        id: 'group1',
        name: 'テストグループ',
        administratorId: 'admin1',
        memo: 'テスト用のグループ',
      );
      testGroups = [
        GroupWithMembers(group: testGroup, members: [testMember]),
      ];
    });

    testWidgets('グループ一覧が表示される', (WidgetTester tester) async {
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => testGroups);

      await tester.pumpWidget(MaterialApp(home: const GroupTimeline()));

      expect(find.text('テストグループ'), findsOneWidget);
    });

    testWidgets('グループをタップすると年表が表示される', (WidgetTester tester) async {
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => testGroups);

      await tester.pumpWidget(MaterialApp(home: const GroupTimeline()));

      await tester.tap(find.text('テストグループ'));
      await tester.pumpAndSettle();

      expect(find.text('テストグループ年表'), findsOneWidget);
    });

    testWidgets('グループが存在しない場合は空状態を表示する', (WidgetTester tester) async {
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => <GroupWithMembers>[]);

      await tester.pumpWidget(MaterialApp(home: const GroupTimeline()));

      expect(find.text('グループが見つかりません'), findsOneWidget);
    });

    testWidgets('実際のデータを使用してグループ一覧を表示する', (WidgetTester tester) async {
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => testGroups);

      await tester.pumpWidget(
        MaterialApp(
          home: GroupTimeline(
            currentMember: testMember,
            getGroupsWithMembersUsecase: mockGetGroupsWithMembersUsecase,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('グループが見つかりません'), findsNothing);
    });
  });
}
