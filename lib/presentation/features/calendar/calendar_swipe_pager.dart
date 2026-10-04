import 'package:flutter/widgets.dart';
import 'package:memora/presentation/features/calendar/calendar_page_swipe_controller.dart';

class CalendarSwipePager extends StatefulWidget {
  const CalendarSwipePager({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onPageChanged,
    required this.itemBuilder,
  });
  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageChanged;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<CalendarSwipePager> createState() => _CalendarSwipePagerState();
}

class _CalendarSwipePagerState extends State<CalendarSwipePager> {
  late final _swipeController = CalendarPageSwipeController(widget.controller);

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _swipeController.onPointerDown,
    onPointerMove: _swipeController.onPointerMove,
    onPointerUp: _swipeController.onPointerUp,
    onPointerCancel: _swipeController.onPointerCancel,
    child: NotificationListener<ScrollNotification>(
      onNotification: _swipeController.onScrollNotification,
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          child: SizedBox(
            width: constraints.maxWidth.floorToDouble(),
            child: PageView.builder(
              controller: widget.controller,
              pageSnapping: false,
              physics: _CalendarPageScrollPhysics(
                targetPage: () => _swipeController.targetPage,
              ),
              itemCount: widget.itemCount,
              onPageChanged: widget.onPageChanged,
              itemBuilder: widget.itemBuilder,
            ),
          ),
        ),
      ),
    ),
  );
}

class _CalendarPageScrollPhysics extends PageScrollPhysics {
  const _CalendarPageScrollPhysics({required this.targetPage, super.parent});
  final int? Function() targetPage;

  @override
  _CalendarPageScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _CalendarPageScrollPhysics(
        targetPage: targetPage,
        parent: buildParent(ancestor),
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final page = targetPage();
    if (page == null) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = (page * position.viewportDimension).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
