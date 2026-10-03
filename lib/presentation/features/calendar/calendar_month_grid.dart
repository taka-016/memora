import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_week_layout.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

class CalendarMonthGrid extends StatefulWidget {
  const CalendarMonthGrid({
    super.key,
    required this.state,
    required this.onSelectDay,
    required this.onMoveMonth,
  });
  final CalendarState state;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<int> onMoveMonth;

  @override
  State<CalendarMonthGrid> createState() => _CalendarMonthGridState();
}

class _CalendarMonthGridState extends State<CalendarMonthGrid> {
  late final PageController _pageController;
  late int _pageIndex;
  int? _swipeStartPage;

  int _indexForMonth(DateTime month) => (month.year - 1) * 12 + month.month - 1;

  @override
  void initState() {
    super.initState();
    _pageIndex = _indexForMonth(widget.state.month);
    _pageController = PageController(initialPage: _pageIndex, keepPage: false);
  }

  @override
  void didUpdateWidget(CalendarMonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _indexForMonth(widget.state.month);
    if (target == _pageIndex) {
      return;
    }
    _pageIndex = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _pageController.hasClients &&
          _indexForMonth(widget.state.month) == target) {
        _pageController.jumpToPage(target);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 && notification.metrics is PageMetrics) {
            if (notification is ScrollStartNotification) {
              _swipeStartPage = notification.dragDetails == null
                  ? null
                  : _pageController.page?.round();
            } else if (notification is ScrollEndNotification) {
              _swipeStartPage = null;
            }
          }
          return false;
        },
        child: PageView.builder(
          key: const Key('calendar_month_grid'),
          controller: _pageController,
          pageSnapping: false,
          physics: _CalendarMonthScrollPhysics(
            swipeStartPage: () => _swipeStartPage,
          ),
          itemCount: 9999 * 12,
          onPageChanged: (index) {
            final offset = index - _pageIndex;
            _pageIndex = index;
            if (offset != 0) {
              widget.onMoveMonth(offset);
            }
          },
          itemBuilder: (context, index) {
            final month = DateTime(index ~/ 12 + 1, index % 12 + 1);
            return _CalendarMonthPage(
              key: ValueKey('calendar_month_${month.year}_${month.month}'),
              state: widget.state,
              month: month,
              onSelectDay: widget.onSelectDay,
            );
          },
        ),
      );
}

class _CalendarMonthScrollPhysics extends PageScrollPhysics {
  const _CalendarMonthScrollPhysics({
    required this.swipeStartPage,
    super.parent,
  });
  final int? Function() swipeStartPage;
  static const _SWIPE_DISTANCE_THRESHOLD = .3;

  @override
  _CalendarMonthScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _CalendarMonthScrollPhysics(
        swipeStartPage: swipeStartPage,
        parent: buildParent(ancestor),
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final start = swipeStartPage();
    if (start == null ||
        (velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final page = position.pixels / position.viewportDimension;
    final distance = page - start;
    final double targetPage;
    if (velocity.abs() > tolerance.velocity) {
      targetPage = (page + .5 * velocity.sign).roundToDouble();
    } else {
      targetPage = distance.abs() >= _SWIPE_DISTANCE_THRESHOLD
          ? start + distance.sign
          : start.toDouble();
    }
    final target = (targetPage * position.viewportDimension).clamp(
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

class _CalendarMonthPage extends StatelessWidget {
  const _CalendarMonthPage({
    super.key,
    required this.state,
    required this.month,
    required this.onSelectDay,
  });
  final CalendarState state;
  final DateTime month;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstOffset = month.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((firstOffset + days) / 7).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final minHeight =
            16 + textScaler.scale(14) * 1.4 + textScaler.scale(11) * 1.4 * 4;
        final rowHeight = math.max(constraints.maxHeight / rows, minHeight);
        return SingleChildScrollView(
          child: Column(
            children: [
              for (var row = 0; row < rows; row++)
                Container(
                  height: rowHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: .5,
                      ),
                    ),
                  ),
                  child: _CalendarWeekRow(
                    state: state,
                    weekStart: DateTime(
                      month.year,
                      month.month,
                      row * 7 - firstOffset + 1,
                    ),
                    month: month,
                    onSelectDay: onSelectDay,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    required this.state,
    required this.weekStart,
    required this.month,
    required this.onSelectDay,
  });
  final CalendarState state;
  final DateTime weekStart;
  final DateTime month;
  final ValueChanged<DateTime> onSelectDay;
  @override
  Widget build(BuildContext context) {
    final layout = CalendarWeekLayout(
      state: state,
      weekStart: weekStart,
      month: month,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final laneHeight = scaler.scale(11) * 1.4 + 2;
    final eventTop = 2 + scaler.scale(14) * 1.4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / 7;
        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final date = DateTime(
                          weekStart.year,
                          weekStart.month,
                          weekStart.day + column,
                        );
                        if (date.month != month.month ||
                            date.year != month.year) {
                          return const SizedBox.shrink();
                        }
                        return _CalendarDayCell(
                          state: state,
                          date: date,
                          entries: layout.entries
                              .where(
                                (entry) =>
                                    entry.startColumn == column &&
                                    entry.endColumn == column,
                              )
                              .toList(),
                          visibleCount: layout.visibleCounts[column],
                          laneHeight: laneHeight,
                          onTap: state.isSaving
                              ? null
                              : () => onSelectDay(date),
                        );
                      },
                    ),
                  ),
              ],
            ),
            for (final entry in layout.entries.where(
              (entry) => entry.startColumn != entry.endColumn,
            ))
              Positioned(
                left: width * entry.startColumn + 2,
                width: width * (entry.endColumn - entry.startColumn + 1) - 4,
                top: eventTop + entry.lane * laneHeight,
                child: IgnorePointer(
                  child: _CalendarEventPreview(
                    key: Key(
                      'calendar_event_${entry.event.id}_${weekStart.year}_${weekStart.month}_${weekStart.day}',
                    ),
                    state: state,
                    event: entry.event,
                    centered: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.state,
    required this.date,
    required this.onTap,
    required this.entries,
    required this.visibleCount,
    required this.laneHeight,
  });
  final CalendarState state;
  final DateTime date;
  final VoidCallback? onTap;
  final List<CalendarWeekEntry> entries;
  final int visibleCount;
  final double laneHeight;
  @override
  Widget build(BuildContext context) {
    final remaining = state.eventsForDay(date).length - visibleCount;
    final selected = date == state.selectedDate;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${calendarDateText(date)}、予定${state.eventsForDay(date).length}件${selected ? '、再タップで予定一覧' : ''}',
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: .35)
            : Colors.transparent,
        child: InkWell(
          key: Key('calendar_day_${date.year}_${date.month}_${date.day}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${date.day}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                for (var lane = 0; lane < 3; lane++)
                  SizedBox(
                    height: laneHeight,
                    child: Builder(
                      builder: (context) {
                        final entry = entries
                            .where((entry) => entry.lane == lane)
                            .firstOrNull;
                        return entry == null
                            ? const SizedBox.shrink()
                            : _CalendarEventPreview(
                                state: state,
                                event: entry.event,
                              );
                      },
                    ),
                  ),
                if (remaining > 0)
                  Text(
                    '他$remaining件',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 11, height: 1.4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarEventPreview extends StatelessWidget {
  const _CalendarEventPreview({
    super.key,
    required this.state,
    required this.event,
    this.centered = false,
  });
  final CalendarState state;
  final CalendarEventDto event;
  final bool centered;
  @override
  Widget build(BuildContext context) {
    final label = state.labels
        .where((label) => label.id == event.labelId)
        .firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    final color = label == null
        ? scheme.surfaceContainerHighest
        : calendarLabelColor(label.color);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Semantics(
        label: '${event.title}、${label?.name ?? '色ラベルを確認してください'}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: event.isAllDay ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: label == null
                  ? scheme.onSurface
                  : calendarLabelColor(
                      event.isAllDay ? label.textColor : label.color,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
