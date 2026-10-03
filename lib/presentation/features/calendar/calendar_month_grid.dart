import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
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
    if (target == _pageIndex) return;
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
  Widget build(BuildContext context) => PageView.builder(
    key: const Key('calendar_month_grid'),
    controller: _pageController,
    itemCount: 9999 * 12,
    onPageChanged: (index) {
      _pageIndex = index;
      final offset = index - _indexForMonth(widget.state.month);
      if (offset != 0) widget.onMoveMonth(offset);
    },
    itemBuilder: (context, index) => _CalendarMonthPage(
      key: ValueKey('calendar_month_${index ~/ 12 + 1}_${index % 12 + 1}'),
      state: widget.state,
      month: DateTime(index ~/ 12 + 1, index % 12 + 1),
      onSelectDay: widget.onSelectDay,
    ),
  );
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < 7; column++)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final day = row * 7 + column - firstOffset + 1;
                              if (day < 1 || day > days)
                                return const SizedBox.shrink();
                              final date = DateTime(
                                month.year,
                                month.month,
                                day,
                              );
                              return _CalendarDayCell(
                                state: state,
                                date: date,
                                onTap: state.isSaving
                                    ? null
                                    : () => onSelectDay(date),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
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
  });
  final CalendarState state;
  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final events = state.eventsForDay(date);
    final selected = date == state.selectedDate;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${calendarDateText(date)}、予定${events.length}件${selected ? '、再タップで予定一覧' : ''}',
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: .35)
            : Colors.transparent,
        child: InkWell(
          key: Key('calendar_day_${date.year}_${date.month}_${date.day}'),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${date.day}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                for (final event in events.take(3)) _preview(context, event),
                if (events.length > 3)
                  Text(
                    '他${events.length - 3}件',
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

  Widget _preview(BuildContext context, CalendarEventDto event) {
    final label = state.labels
        .where((label) => label.id == event.labelId)
        .firstOrNull;
    final color = label == null
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : calendarLabelColor(label.color);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Semantics(
        label: '${event.title}、${label?.name ?? '色ラベルを確認してください'}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: color.computeLuminance() > .179
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
