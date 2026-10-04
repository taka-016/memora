import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/calendar_page_swipe_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'calendar_page_swipe_controller_test.mocks.dart';

@GenerateMocks([PageController, BuildContext])
void main() {
  late MockPageController pages;
  late CalendarPageSwipeController controller;
  late MockBuildContext context;
  late PageMetrics metrics;

  void move(int milliseconds, double x, {int pointer = 1}) {
    controller.onPointerMove(
      PointerMoveEvent(
        pointer: pointer,
        timeStamp: Duration(milliseconds: milliseconds),
        position: Offset(x, 0),
      ),
    );
  }

  void release(int milliseconds, double x) {
    controller.onPointerUp(
      PointerUpEvent(
        pointer: 1,
        timeStamp: Duration(milliseconds: milliseconds),
        position: Offset(x, 0),
      ),
    );
  }

  void begin() {
    controller.onPointerDown(
      const PointerDownEvent(pointer: 1, position: Offset(100, 0)),
    );
    controller.onScrollNotification(
      ScrollStartNotification(
        metrics: metrics,
        context: context,
        dragDetails: DragStartDetails(globalPosition: Offset.zero),
      ),
    );
  }

  setUp(() {
    pages = MockPageController();
    when(pages.hasClients).thenReturn(true);
    when(pages.page).thenReturn(20);
    context = MockBuildContext();
    metrics = PageMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 120000,
      pixels: 16000,
      viewportDimension: 800,
      axisDirection: AxisDirection.right,
      viewportFraction: 1,
      devicePixelRatio: 1,
    );
    controller = CalendarPageSwipeController(pages);
  });

  for (final direction in [-1, 1]) {
    test('少ない移動サンプルと短い離指の間隔でもページを切り替える（$direction）', () {
      begin();
      move(20, 100 + 20.0 * direction);
      move(100, 100 + 60.0 * direction);
      when(pages.page).thenReturn(20 - .1 * direction);
      release(190, 100 + 60.0 * direction);
      expect(controller.targetPage, 20 - direction);
    });

    for (final distance in [.35, .45]) {
      test('微速時は4割の距離を基準にする（$direction、$distance）', () {
        begin();
        move(1000, 100 + (800 * distance - 4) * direction);
        move(2000, 100 + 800 * distance * direction);
        when(pages.page).thenReturn(20 - distance * direction);
        release(2010, 100 + 800 * distance * direction);
        expect(controller.targetPage, distance < .4 ? 20 : 20 - direction);
      });

      test('止めてから離した場合も4割の距離を基準にする（$direction、$distance）', () {
        begin();
        move(20, 100 + 20.0 * direction);
        move(100, 100 + 800 * distance * direction);
        when(pages.page).thenReturn(20 - distance * direction);
        release(400, 100 + 800 * distance * direction);
        expect(controller.targetPage, distance < .4 ? 20 : 20 - direction);
      });
    }
  }

  test('最後に向きを戻した場合は逆隣の月へ飛ばず元の月へ戻る', () {
    begin();
    move(80, 40);
    move(140, 60);
    when(pages.page).thenReturn(20.2);
    release(150, 60);
    expect(controller.targetPage, 20);
  });

  test('別の指は判定へ混ざらずキャンセル後は次のスワイプを受け付ける', () {
    begin();
    controller.onPointerDown(const PointerDownEvent(pointer: 2));
    move(10, -1000, pointer: 2);
    move(20, 80);
    when(pages.page).thenReturn(20.1);
    controller.onPointerCancel(const PointerCancelEvent(pointer: 1));
    expect(controller.targetPage, 20);
    controller.onScrollNotification(
      ScrollEndNotification(metrics: metrics, context: context),
    );
    expect(controller.targetPage, isNull);
    begin();
    move(100, 160);
    when(pages.page).thenReturn(19.9);
    release(130, 160);
    expect(controller.targetPage, 19);
  });

  test('日付タップとプログラムによる月移動をスワイプと扱わない', () {
    controller.onPointerDown(const PointerDownEvent(pointer: 1));
    move(10, 2);
    release(20, 2);
    expect(controller.targetPage, isNull);
    controller.onScrollNotification(
      ScrollStartNotification(metrics: metrics, context: context),
    );
    expect(controller.targetPage, isNull);
  });
}
