// coverage:ignore-file
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/main.dart';

void main() {
  testWidgets('トップメニューが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ダミー機能A'), findsOneWidget);
    expect(find.text('ダミー機能B'), findsOneWidget);
    expect(find.text('トップメニュー'), findsOneWidget);
    expect(find.text('マップ表示'), findsOneWidget);
  });
}
