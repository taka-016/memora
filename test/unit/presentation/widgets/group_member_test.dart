import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/group_list.dart';

import 'group_member_test.mocks.dart';

@GenerateMocks([GetGroupsWithMembersUsecase])
void main() {
  late MockGetGroupsWithMembersUsecase mockUsecase;
  late Member testMember;

  setUp(() {
    mockUsecase = MockGetGroupsWithMembersUsecase();
    testMember = Member(
      id: 'admin1',
      hiraganaFirstName: 'たろう',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '太郎',
      kanjiLastName: '山田',
      firstName: 'Taro',
      lastName: 'Yamada',
      displayName: 'タロちゃん',
      type: 'family',
      birthday: DateTime(1990, 1, 1),
      gender: 'male',
    );
  });

  Widget createTestWidget({Member? member}) {
    return MaterialApp(
      home: Scaffold(
        body: GroupList(
          getGroupsWithMembersUsecase: mockUsecase,
          member: member ?? testMember,
        ),
      ),
    );
  }

  group('GroupList', () {
    testWidgets('メンバー引数を受け取るコンストラクタが正常に動作する', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
          members: [testMember],
        ),
      ];
      when(
        mockUsecase.execute(testMember),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_member')), findsOneWidget);
      verify(mockUsecase.execute(testMember)).called(1);
    });

    testWidgets('複数のグループがある場合、グループ一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final member1 = Member(
        id: 'member1',
        kanjiFirstName: '太郎',
        kanjiLastName: '田中',
        displayName: '田中',
      );
      final member2 = Member(
        id: 'member2',
        kanjiFirstName: '花子',
        kanjiLastName: '佐藤',
        displayName: '佐藤',
      );
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: [member1],
        ),
        GroupWithMembers(
          group: Group(id: '2', administratorId: 'admin1', name: 'グループ2'),
          members: [member2],
        ),
      ];
      when(
        mockUsecase.execute(testMember),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('グループ2'), findsOneWidget);
      expect(find.text('1人のメンバー'), findsNWidgets(2));
      expect(find.byIcon(Icons.arrow_forward_ios), findsNWidgets(2));
    });

    testWidgets('グループが1つの場合でも、グループ一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final member1 = Member(
        id: 'member1',
        kanjiFirstName: '太郎',
        kanjiLastName: '田中',
        displayName: '田中',
      );
      final member2 = Member(
        id: 'member2',
        kanjiFirstName: '花子',
        kanjiLastName: '佐藤',
        displayName: '佐藤',
      );
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
          members: [member1, member2],
        ),
      ];
      when(
        mockUsecase.execute(testMember),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('2人のメンバー'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('グループが存在しない場合、空状態が表示される', (WidgetTester tester) async {
      // Arrange
      when(mockUsecase.execute(testMember)).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループがありません'), findsOneWidget);
      expect(find.text('グループを作成'), findsNothing);
    });

    testWidgets('ローディング中はCircularProgressIndicatorが表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final completer = Completer<List<GroupWithMembers>>();
      when(mockUsecase.execute(testMember)).thenAnswer((_) => completer.future);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // ローディング状態のみポンプ

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('エラーが発生した場合、エラー状態が表示される', (WidgetTester tester) async {
      // Arrange
      when(mockUsecase.execute(testMember)).thenThrow(Exception('テストエラー'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });

    testWidgets('エラー状態で再読み込みボタンをタップすると、再度データを読み込む', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockUsecase.execute(testMember)).thenThrow(Exception('テストエラー'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 正常なデータを返すように変更
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
          members: [testMember],
        ),
      ];
      when(
        mockUsecase.execute(testMember),
      ).thenAnswer((_) async => groupsWithMembers);

      // 再読み込みボタンをタップ
      await tester.tap(find.text('再読み込み'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('エラーが発生しました'), findsNothing);
      verify(mockUsecase.execute(testMember)).called(2); // 最初のエラー + 再読み込み
    });

    testWidgets('グループ一覧でメンバー数が表示される', (WidgetTester tester) async {
      // Arrange
      final memberWithNickname = Member(
        id: 'member_with_nickname',
        kanjiFirstName: '太郎',
        kanjiLastName: '田中',
        displayName: 'タロちゃん',
      );
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
          members: [memberWithNickname],
        ),
      ];
      when(
        mockUsecase.execute(testMember),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('1人のメンバー'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('グループ行をタップしたときにコールバック関数が呼ばれる', (WidgetTester tester) async {
      // Arrange
      GroupWithMembers? selectedGroup;
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
          members: [testMember],
        ),
      ];
      when(
        mockUsecase.execute(testMember),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupList(
              getGroupsWithMembersUsecase: mockUsecase,
              member: testMember,
              onGroupSelected: (groupWithMembers) {
                selectedGroup = groupWithMembers;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // グループ行をタップ
      await tester.tap(find.text('テストグループ'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedGroup, isNotNull);
      expect(selectedGroup!.group.id, '1');
      expect(selectedGroup!.group.name, 'テストグループ');
    });
  });
}
