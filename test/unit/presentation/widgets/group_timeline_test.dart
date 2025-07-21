import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/group_timeline.dart';

void main() {
  late Member testMember;
  late GroupWithMembers testGroupWithMembers;

  setUp(() {
    testMember = Member(
      id: 'member1',
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

    testGroupWithMembers = GroupWithMembers(
      group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
      members: [testMember],
    );
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: GroupTimeline(groupWithMembers: testGroupWithMembers),
      ),
    );
  }

  group('GroupTimeline', () {
    testWidgets('GroupTimelineウィジェットが正しく表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
    });

    testWidgets('グループ名が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('テストグループ'), findsOneWidget);
    });

    testWidgets('年表のヘッダー行に年の列が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // 現在の年（2025年(令和7年)）が表示されることを確認
      final currentYear = DateTime.now().year;
      final eraYear = currentYear - 2018; // 令和元年は2019年
      expect(find.text('$currentYear年(令和$eraYear年)'), findsOneWidget);
    });

    testWidgets('年表の行にメンバー名が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('タロちゃん'), findsOneWidget);
    });
  });
}
