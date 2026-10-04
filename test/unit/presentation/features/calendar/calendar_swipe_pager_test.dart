import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/calendar_swipe_pager.dart';

void main() {
  for (final daily in [false, true]) {
    testWidgets('小数の画面幅でも年月日の全範囲を描画し前後へスワイプできる（$daily）', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final first = DateTime.utc(1);
      final date = DateTime.utc(2026, 10, 4);
      final count = daily
          ? DateTime.utc(9999, 12, 31).difference(first).inDays + 1
          : 9999 * 12;
      final initial = daily
          ? date.difference(first).inDays
          : (date.year - 1) * 12 + date.month - 1;
      final controller = PageController(initialPage: initial, keepPage: false);
      addTearDown(controller.dispose);
      var selected = initial;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CalendarSwipePager(
            controller: controller,
            itemCount: count,
            onPageChanged: (value) => selected = value,
            itemBuilder: (context, index) => Center(child: Text('ページ$index')),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('ページ$initial'), findsOneWidget);
      await tester.drag(find.byType(CalendarSwipePager), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(selected, initial + 1);
      expect(find.text('ページ${initial + 1}'), findsOneWidget);
      await tester.drag(find.byType(CalendarSwipePager), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(selected, initial);
      expect(tester.takeException(), isNull);
    });
  }
}
