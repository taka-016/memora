// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  testWidgets('トップメニューが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ダミー機能A'), findsOneWidget);
    expect(find.text('ダミー機能B'), findsOneWidget);
    expect(find.text('トップメニュー'), findsOneWidget);
    expect(find.text('マップ表示'), findsOneWidget);
  });

  testWidgets('マップ表示メニューをタップするとGoogleMap画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 「マップ表示」メニューをタップ
    await tester.tap(find.text('マップ表示'));
    await tester.pumpAndSettle();

    // AppBarタイトル確認
    expect(find.text('Googleマップ'), findsOneWidget);

    // GoogleMapウィジェットが存在することを確認
    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
