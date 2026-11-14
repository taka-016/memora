import 'package:memora/presentation/features/calendar/calendar_preview_text.dart';
import 'package:memora/presentation/features/calendar/calendar_holiday_banner.dart';
import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/application/services/calendar/japanese_calendar.dart';
import 'package:memora/presentation/features/calendar/calendar_date_color.dart';
import 'package:flutter/material.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_week_layout.dart';
import 'package:memora/presentation/features/calendar/calendar_swipe_pager.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

class CalendarMonthGrid extends StatefulWidget {
  const CalendarMonthGrid({
    super.key,
    required this.state,
    required this.onSelectDay,
    required this.onMoveMonth,
    this.settings = const CalendarDisplaySettings(),
  });
  final CalendarDisplaySettings settings;
  final CalendarState state;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<int> onMoveMonth;

  @override
  State<CalendarMonthGrid> createState() => _CalendarMonthGridState();
}

class _CalendarMonthGridState extends State<CalendarMonthGrid> {
  late final PageController _pageController;
  late int _pageIndex;

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
  Widget build(BuildContext context) => CalendarSwipePager(
    key: const Key('calendar_month_grid'),
    controller: _pageController,
    itemCount: 9999 * 12,
    onPageChanged: (index) {
      final offset = index - _pageIndex;
      _pageIndex = index;
      if (offset != 0) widget.onMoveMonth(offset);
    },
    itemBuilder: (context, index) {
      final month = DateTime(index ~/ 12 + 1, index % 12 + 1);
      return _CalendarMonthPage(
        key: ValueKey('calendar_month_${month.year}_${month.month}'),
        state: widget.state,
        settings: widget.settings,
        month: month,
        onSelectDay: widget.onSelectDay,
      );
    },
  );
}

class _CalendarMonthPage extends StatelessWidget {
  const _CalendarMonthPage({
    super.key,
    required this.state,
    required this.settings,
    required this.month,
    required this.onSelectDay,
  });
  final CalendarDisplaySettings settings;
  final CalendarState state;
  final DateTime month;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstOffset = (month.weekday - settings.weekStart.weekday + 7) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((firstOffset + days) / 7).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            for (var row = 0; row < rows; row++)
              Expanded(
                child: Container(
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
                    showRokuyo: settings.showRokuyo,
                    weekStart: DateTime(
                      month.year,
                      month.month,
                      row * 7 - firstOffset + 1,
                    ),
                    month: month,
                    onSelectDay: onSelectDay,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    required this.state,
    required this.showRokuyo,
    required this.weekStart,
    required this.month,
    required this.onSelectDay,
  });
  final bool showRokuyo;
  final CalendarState state;
  final DateTime weekStart;
  final DateTime month;
  final ValueChanged<DateTime> onSelectDay;
  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final laneHeight = scaler.scale(11) * 1.4 + 2;
    final eventTop = 2 + scaler.scale(14) * 1.4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxVisibleEvents =
            ((constraints.maxHeight - eventTop - 2) / laneHeight).floor().clamp(
              0,
              CalendarWeekLayout.MAX_VISIBLE_EVENTS,
            );
        final layout = CalendarWeekLayout(
          state: state,
          weekStart: weekStart,
          month: month,
          maxVisibleEvents: maxVisibleEvents,
          isHoliday: (date) => JapaneseCalendar.holidayName(date) != null,
        );
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
                          showRokuyo: showRokuyo,
                          date: date,
                          entries: layout.entries
                              .where(
                                (entry) =>
                                    entry.startColumn == column &&
                                    entry.endColumn == column,
                              )
                              .toList(),
                          visibleCount: layout.visibleCounts[column],
                          maxVisibleEvents: maxVisibleEvents,
                          lastLaneOccupied: layout.entries.any(
                            (entry) =>
                                entry.lane == maxVisibleEvents - 1 &&
                                entry.startColumn <= column &&
                                entry.endColumn >= column,
                          ),
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
                      'calendar_event_${entry.event.groupId}_${entry.event.id}_${entry.event.originalStartDateTime?.microsecondsSinceEpoch}_${weekStart.year}_${weekStart.month}_${weekStart.day}',
                    ),
                    state: state,
                    event: entry.event,
                    filled: entry.event.isAllDay || entry.isMultiDay,
                  ),
                ),
              ),
            for (var column = 0; column < 7; column++)
              if (layout.entries.any(
                (entry) =>
                    entry.lane == maxVisibleEvents - 1 &&
                    entry.startColumn != entry.endColumn &&
                    entry.startColumn <= column &&
                    entry.endColumn >= column,
              ))
                Builder(
                  builder: (context) {
                    final date = DateTime(
                      weekStart.year,
                      weekStart.month,
                      weekStart.day + column,
                    );
                    final remaining =
                        state.eventsForDay(date).length -
                        layout.visibleCounts[column];
                    if (remaining <= 0) return const SizedBox.shrink();
                    return Positioned(
                      left: width * column + 2,
                      width: width - 4,
                      top: eventTop + (maxVisibleEvents - 1) * laneHeight,
                      height: laneHeight,
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: _CalendarRemainingCount(
                            count: remaining,
                            selected: date == state.selectedDate,
                          ),
                        ),
                      ),
                    );
                  },
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
    required this.showRokuyo,
    required this.date,
    required this.onTap,
    required this.entries,
    required this.visibleCount,
    required this.maxVisibleEvents,
    required this.lastLaneOccupied,
    required this.laneHeight,
  });
  final bool showRokuyo;
  final CalendarState state;
  final DateTime date;
  final VoidCallback? onTap;
  final List<CalendarWeekEntry> entries;
  final int visibleCount;
  final int maxVisibleEvents;
  final bool lastLaneOccupied;
  final double laneHeight;
  @override
  Widget build(BuildContext context) {
    final remaining = state.eventsForDay(date).length - visibleCount;
    final selected = date == state.selectedDate;
    final holiday = JapaneseCalendar.holidayName(date);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${calendarDateText(date)}${JapaneseCalendar.holidayName(date) == null ? '' : '、${JapaneseCalendar.holidayName(date)}'}、予定${state.eventsForDay(date).length}件${selected ? '、再タップで予定一覧' : ''}',
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
                SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(14) * 1.4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: calendarDateColor(
                              date,
                              Theme.of(context).brightness,
                            ),
                          ),
                        ),
                        if (showRokuyo) ...[
                          const SizedBox(width: 2),
                          Text(
                            JapaneseCalendar.rokuyo(date),
                            style: const TextStyle(fontSize: 8, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                for (var lane = 0; lane < maxVisibleEvents; lane++)
                  SizedBox(
                    height: laneHeight,
                    child: Builder(
                      builder: (context) {
                        if (lane == 0 && holiday != null) {
                          final banner = CalendarHolidayBanner(
                            name: holiday,
                            compact: true,
                          );
                          if (maxVisibleEvents == 1 && remaining > 0) {
                            return Row(
                              children: [
                                Expanded(child: banner),
                                _CalendarRemainingCount(
                                  count: remaining,
                                  selected: selected,
                                ),
                              ],
                            );
                          }
                          return banner;
                        }
                        final entry = entries
                            .where((entry) => entry.lane == lane)
                            .firstOrNull;
                        if (entry == null) {
                          if (lane == maxVisibleEvents - 1 &&
                              remaining > 0 &&
                              !lastLaneOccupied) {
                            return Align(
                              alignment: Alignment.bottomRight,
                              child: _CalendarRemainingCount(
                                count: remaining,
                                selected: selected,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        final preview = _CalendarEventPreview(
                          state: state,
                          event: entry.event,
                          filled: entry.event.isAllDay || entry.isMultiDay,
                        );
                        if (lane == maxVisibleEvents - 1 && remaining > 0) {
                          return Row(
                            children: [
                              Expanded(child: preview),
                              Align(
                                alignment: Alignment.bottomRight,
                                widthFactor: 1,
                                child: _CalendarRemainingCount(
                                  count: remaining,
                                  selected: selected,
                                ),
                              ),
                            ],
                          );
                        }
                        return preview;
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarRemainingCount extends StatelessWidget {
  const _CalendarRemainingCount({required this.count, required this.selected});
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '他$count件',
      child: Container(
        color: selected
            ? Color.alphaBlend(
                scheme.primaryContainer.withValues(alpha: .35),
                scheme.surface,
              )
            : scheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Text(
          '+$count',
          maxLines: 1,
          style: const TextStyle(fontSize: 9, height: 1.4),
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
    required this.filled,
  });
  final CalendarState state;
  final CalendarEventDto event;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final label = state.displayLabels
        .where(
          (label) =>
              label.id == event.labelKey && label.groupId == event.groupId,
        )
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
            color: filled ? color : Colors.transparent,
            borderRadius: filled ? BorderRadius.circular(3) : null,
            border: filled
                ? null
                : Border(left: BorderSide(color: color, width: 3)),
          ),
          child: CalendarPreviewText(
            text: event.title,
            centerWhenFits: filled,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: filled && label != null
                  ? calendarLabelColor(label.textColor)
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
