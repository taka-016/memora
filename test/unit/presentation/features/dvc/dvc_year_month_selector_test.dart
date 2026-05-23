import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/dvc/dvc_year_month_selector.dart';
import 'package:memora/presentation/shared/dialogs/custom_date_picker_dialog.dart';

void main() {
  group('DvcYearMonthSelector', () {
    testWidgets('年月選択に共通DatePickerを使用すること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DvcYearMonthSelector(
              label: '開始年月',
              selected: DateTime(2027, 8),
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('2027-08'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomDatePickerDialog), findsOneWidget);
      expect(find.text('2027年8月1日 (日)'), findsOneWidget);
    });
  });
}
