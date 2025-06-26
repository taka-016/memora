import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/user_drawer_header.dart';

void main() {
  Widget createTestWidget({Member? member}) {
    return MaterialApp(
      home: Scaffold(body: UserDrawerHeader(member: member)),
    );
  }

  group('UserDrawerHeader', () {
    testWidgets('ニックネームが設定されている場合、ニックネームが表示される', (WidgetTester tester) async {
      // Arrange
      final member = Member(
        id: 'member123',
        nickname: 'テストユーザー',
        kanjiLastName: '田中',
        kanjiFirstName: '太郎',
      );

      // Act
      await tester.pumpWidget(createTestWidget(member: member));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('田中 太郎'), findsNothing);
    });

    testWidgets('ニックネームが未設定で漢字姓名が設定されている場合、漢字姓名が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final member = Member(
        id: 'member123',
        kanjiLastName: '田中',
        kanjiFirstName: '太郎',
      );

      // Act
      await tester.pumpWidget(createTestWidget(member: member));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('田中 太郎'), findsOneWidget);
    });

    testWidgets('kanjiLastNameとkanjiFirstNameが両方未設定の場合、名前未設定が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final member = Member(id: 'member123');

      // Act
      await tester.pumpWidget(createTestWidget(member: member));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('名前未設定'), findsOneWidget);
    });

    testWidgets('メンバー情報が取得できない場合、名前未設定が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(member: null));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('名前未設定'), findsOneWidget);
    });
  });
}
