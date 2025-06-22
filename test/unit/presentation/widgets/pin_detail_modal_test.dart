import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/widgets/pin_detail_modal.dart';

void main() {
  testWidgets('PinDetailModalが正しく表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PinDetailModal(onSave: null, onDelete: null, onClose: null),
        ),
      ),
    );

    expect(find.text('保存'), findsOneWidget);
    expect(find.text('削除'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('詳細入力画面のUI要素が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PinDetailModal())),
    );

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byKey(const Key('visitStartDateField')), findsOneWidget);
    expect(find.byKey(const Key('visitEndDateField')), findsOneWidget);
    expect(find.byKey(const Key('visitMemoField')), findsOneWidget);
  });
}
