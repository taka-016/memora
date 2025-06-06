import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/presentation/widgets/search_bar.dart';

void main() {
  testWidgets('検索バーが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CustomSearchBar(hintText: '場所を検索')),
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('場所を検索'), findsOneWidget);
  });
}
