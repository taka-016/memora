import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/user_drawer_header.dart';

void main() {
  Widget createTestWidget({required Member member}) {
    return MaterialApp(
      home: Scaffold(body: UserDrawerHeader(member: member)),
    );
  }

  group('UserDrawerHeader', () {
    testWidgets('表示名が表示される', (WidgetTester tester) async {
      // Arrange
      final member = Member(
        id: 'member123',
        displayName: 'テストユーザー',
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
  });
}
