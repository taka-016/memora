import 'package:flutter/widgets.dart';

class CalendarMonthSwipeController {
  CalendarMonthSwipeController(this._pageController);
  final PageController _pageController;
  final List<({Duration time, double x})> _samples = [];
  int? _pointer;
  int? _startPage;
  int? targetPage;

  void onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _samples
      ..clear()
      ..add((time: event.timeStamp, x: event.position.dx));
  }

  void onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer ||
        (_samples.isNotEmpty && _samples.last.x == event.position.dx)) {
      return;
    }
    _samples.add((time: event.timeStamp, x: event.position.dx));
    final oldest = event.timeStamp - const Duration(milliseconds: 200);
    while (_samples.length > 2 && _samples[1].time < oldest) {
      _samples.removeAt(0);
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final start = _startPage;
    if (start != null && _pageController.hasClients) {
      final velocity = _releaseVelocity(event.timeStamp);
      final page = _pageController.page!;
      final distance = page - start;
      targetPage = velocity.abs() > 10
          ? (velocity < 0 ? page.ceil() : page.floor())
          : distance.abs() >= .4
          ? start + distance.sign.toInt()
          : start;
    }
    _pointer = null;
    _samples.clear();
  }

  void onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    targetPage = _startPage;
    _pointer = null;
    _samples.clear();
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics is! PageMetrics) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _startPage = notification.dragDetails == null
          ? null
          : _pageController.page?.round();
      targetPage = null;
    } else if (notification is ScrollEndNotification) {
      _startPage = null;
      targetPage = null;
    }
    return false;
  }

  double _releaseVelocity(Duration releasedAt) {
    if (_samples.length < 2 ||
        releasedAt - _samples.last.time >= const Duration(milliseconds: 200)) {
      return 0;
    }
    final last = _samples.last;
    var first = last;
    var next = last;
    double direction = 0;
    for (var index = _samples.length - 2; index >= 0; index--) {
      final sample = _samples[index];
      final step = next.x - sample.x;
      if (step != 0) {
        if (direction != 0 && step.sign != direction) break;
        direction = step.sign;
      }
      if (first != last &&
          last.time - sample.time > const Duration(milliseconds: 200)) {
        break;
      }
      first = sample;
      next = sample;
    }
    final elapsed = (releasedAt - first.time).inMicroseconds;
    return elapsed > 0 ? (last.x - first.x) * 1000000 / elapsed : 0;
  }
}
