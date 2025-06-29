import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/group_member.dart';

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
        body: GroupMember(
          getGroupsWithMembersUsecase: mockUsecase,
          member: member ?? testMember,
        ),
      ),
    );
  }

  group('GroupMember', () {
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
    });

    testWidgets('グループが1つの場合、直接メンバー一覧が表示される', (WidgetTester tester) async {
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
      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('田中'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
    });

    testWidgets('グループ一覧からグループを選択するとメンバー一覧が表示される', (WidgetTester tester) async {
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

      // グループ1をタップ
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('田中'), findsOneWidget);
      expect(find.text('佐藤'), findsNothing);
    });

    testWidgets('メンバー一覧から戻るボタンでグループ一覧に戻る', (WidgetTester tester) async {
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

      // グループ1をタップしてメンバー一覧へ
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('グループ2'), findsOneWidget);
    });

    testWidgets('グループが存在しない場合、空状態が表示される', (WidgetTester tester) async {
      // Arrange
      when(mockUsecase.execute(testMember)).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループがありません'), findsOneWidget);
      expect(find.text('グループを作成'), findsOneWidget);
    });

    testWidgets('メンバーがいないグループの場合、空メンバー状態が表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
          members: [],
        ),
      ];
      when(
        mockUsecase.execute(testMember),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('メンバーがいません'), findsOneWidget);
      expect(find.text('メンバーを追加'), findsOneWidget);
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
      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('エラーが発生しました'), findsNothing);
      verify(mockUsecase.execute(testMember)).called(2); // 最初のエラー + 再読み込み
    });

    testWidgets('メンバーが表示される', (WidgetTester tester) async {
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
      expect(find.text('タロちゃん'), findsOneWidget);
    });
  });
}
