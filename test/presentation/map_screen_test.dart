// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/presentation/map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
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
