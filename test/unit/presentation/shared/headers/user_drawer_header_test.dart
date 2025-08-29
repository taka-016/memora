import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/headers/user_drawer_header.dart';

void main() {
  Widget createTestWidget({required String email}) {
    return MaterialApp(
      home: Scaffold(body: UserDrawerHeader(email: email)),
    );
  }

  group('UserDrawerHeader', () {
    testWidgets('メールアドレスが表示される', (WidgetTester tester) async {
      // Arrange
      const email = 'test@example.com';

      // Act
      await tester.pumpWidget(createTestWidget(email: email));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}
