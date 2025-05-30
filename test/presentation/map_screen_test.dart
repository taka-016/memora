// coverage:ignore-file
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verification/presentation/map_screen.dart';

void main() {
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

  testWidgets('マップ画面に現在地ボタンが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('マップ表示'));
    await tester.pumpAndSettle();

    // 現在地ボタン（FloatingActionButton）が存在すること
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  // GoogleMapのピン追加・削除はWidgetテストで直接検証できないため、UIの存在確認のみ行う

  testWidgets('ピンをタップすると削除メニュー付きポップアップが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MapScreen(initialPins: [LatLng(0, 0)])),
    );

    // ピンのFinder（仮: Key('map_pin_0')で1つ目のピンを識別）
    final pinFinder = find.byKey(Key('map_pin_0'));
    expect(pinFinder, findsOneWidget);

    // ピンをタップ
    await tester.tap(pinFinder);
    await tester.pumpAndSettle();

    // ポップアップメニューが表示され、「削除」メニューが存在することを確認
    expect(find.text('削除'), findsOneWidget);
  });
}
