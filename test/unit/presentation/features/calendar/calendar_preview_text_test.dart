import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/calendar_preview_text.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String text,
  double width = 100,
  double scale = 1,
  bool centerWhenFits = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Center(
            child: SizedBox(
              width: width,
              child: CalendarPreviewText(
                text: text,
                style: const TextStyle(fontSize: 14),
                centerWhenFits: centerWhenFits,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('短い名称は中央寄せにし同じ表示幅からはみ出す長い名称は左寄せにする', (tester) async {
    for (final (text, align) in [
      ('文化の日', TextAlign.center),
      ('家族で出かけるとても長い予定の名称', TextAlign.left),
    ]) {
      await _pump(tester, text: text);
      expect(tester.widget<Text>(find.text(text)).textAlign, align);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('文字倍率で名称が収まらなくなった場合は中央から左寄せに切り替える', (tester) async {
    for (final (scale, align) in [
      (1.0, TextAlign.center),
      (2.0, TextAlign.left),
    ]) {
      await _pump(tester, text: '家族旅行', width: 80, scale: scale);
      expect(tester.widget<Text>(find.text('家族旅行')).textAlign, align);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('単日の時間指定予定は短い名称でも左寄せを維持する', (tester) async {
    await _pump(tester, text: '通院', centerWhenFits: false);
    expect(tester.widget<Text>(find.text('通院')).textAlign, TextAlign.left);
  });
}
