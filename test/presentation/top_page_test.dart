import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/top_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'top_page_test.mocks.dart';

@GenerateMocks([GetGroupsWithMembersUsecase])
void main() {
  late MockGetGroupsWithMembersUsecase mockUsecase;

  final testMembers = [
    Member(
      id: 'member1',
      hiraganaFirstName: 'たろう',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '太郎',
      kanjiLastName: '山田',
      firstName: 'Taro',
      lastName: 'Yamada',
      type: 'family',
      birthday: DateTime(1990, 1, 1),
      gender: 'male',
    ),
    Member(
      id: 'member2',
      hiraganaFirstName: 'はなこ',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '花子',
      kanjiLastName: '山田',
      firstName: 'Hanako',
      lastName: 'Yamada',
      type: 'family',
      birthday: DateTime(1985, 5, 10),
      gender: 'female',
    ),
  ];

  setUp(() {
    mockUsecase = MockGetGroupsWithMembersUsecase();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: TopPage(getGroupsWithMembersUsecase: mockUsecase),
    );
  }

  group('TopPage', () {
    testWidgets('グループが複数件ある場合、グループ一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', name: 'グループ1'),
          members: [testMembers[0]],
        ),
        GroupWithMembers(
          group: Group(id: '2', name: 'グループ2'),
          members: [testMembers[1]],
        ),
      ];
      when(mockUsecase.execute()).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('グループ2'), findsOneWidget);
    });

    testWidgets('グループが1件の場合、メンバー一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute()).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('太郎 山田'), findsOneWidget);
      expect(find.text('花子 山田'), findsOneWidget);
      expect(find.text('グループ一覧'), findsNothing);
    });

    testWidgets('グループが0件の場合、グループ作成ボタンが表示される', (WidgetTester tester) async {
      // Arrange
      when(mockUsecase.execute()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループを作成'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('グループにメンバーがいない場合、メンバー追加ボタンが表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', name: 'グループ1'),
          members: [],
        ),
      ];
      when(mockUsecase.execute()).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('メンバーを追加'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('グループを選択すると、そのグループのメンバー一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', name: 'グループ1'),
          members: [testMembers[0]],
        ),
        GroupWithMembers(
          group: Group(id: '2', name: 'グループ2'),
          members: [testMembers[1]],
        ),
      ];
      when(mockUsecase.execute()).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 最初はグループ一覧が表示される
      expect(find.text('グループ一覧'), findsOneWidget);

      // グループ1をタップ
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('太郎 山田'), findsOneWidget);
      expect(find.text('グループ一覧'), findsNothing);
    });

    testWidgets('ローディング中はCircularProgressIndicatorが表示される', (WidgetTester tester) async {
      // Arrange
      when(mockUsecase.execute()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // タイマーを完了させる
      await tester.pumpAndSettle();
    });

    testWidgets('エラーが発生した場合、エラーメッセージが表示される', (WidgetTester tester) async {
      // Arrange
      when(mockUsecase.execute()).thenThrow(Exception('データ取得エラー'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });
  });
}