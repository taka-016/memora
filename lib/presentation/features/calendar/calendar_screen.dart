import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_day_events_sheet.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.onBack,
  });
  final String groupId;
  final String groupName;
  final VoidCallback onBack;
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        unawaited(
          ref.read(calendarNotifierProvider(widget.groupId).notifier).load(),
        );
      }
    });
  }

  void _moveMonth(int offset) {
    final provider = calendarNotifierProvider(widget.groupId);
    final month = ref.read(provider).month;
    if ((offset < 0 && month.year == 1 && month.month == 1) ||
        (offset > 0 && month.year == 9999 && month.month == 12)) {
      return;
    }
    ref
        .read(provider.notifier)
        .selectDate(DateTime(month.year, month.month + offset));
  }

  Future<void> _edit([CalendarEventDto? event]) async {
    final provider = calendarNotifierProvider(widget.groupId);
    if (ref.read(provider).labels.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => CalendarLabelsDialog(groupId: widget.groupId),
      );
      if (!mounted || ref.read(provider).labels.isEmpty) return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => CalendarEventDialog(
        groupId: widget.groupId,
        date: ref.read(provider).selectedDate,
        event: event,
      ),
    );
  }

  Future<void> _selectDay(DateTime date) async {
    final provider = calendarNotifierProvider(widget.groupId);
    final state = ref.read(provider);
    if (state.selectedDate != date) {
      ref.read(provider.notifier).selectDate(date);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CalendarDayEventsSheet(
        groupId: widget.groupId,
        date: date,
        onEdit: (event) => _edit(event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = calendarNotifierProvider(widget.groupId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final month = state.month;
    final firstOffset = month.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((firstOffset + days) / 7).ceil();
    final canEdit =
        !state.isSaving && !state.isLoading && state.loadError.isEmpty;
    return PopScope(
      canPop: !state.isSaving,
      child: SafeArea(
        child: Stack(
          key: const Key('calendar_screen'),
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'グループ選択へ戻る',
                        onPressed: state.isSaving ? null : widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          '${widget.groupName}のカレンダー',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: '再読み込み',
                        onPressed: state.isLoading || state.isSaving
                            ? null
                            : notifier.load,
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        tooltip: '色ラベルの設定',
                        onPressed: canEdit
                            ? () => showDialog<void>(
                                context: context,
                                builder: (context) => CalendarLabelsDialog(
                                  groupId: widget.groupId,
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.palette_outlined),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: '前の月',
                        onPressed: month.year == 1 && month.month == 1
                            ? null
                            : () => _moveMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${month.year}年${month.month}月',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '次の月',
                        onPressed: month.year == 9999 && month.month == 12
                            ? null
                            : () => _moveMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  if (state.isLoading) const LinearProgressIndicator(),
                  if (state.loadError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(state.loadError)),
                          TextButton(
                            onPressed: state.isLoading || state.isSaving
                                ? null
                                : notifier.load,
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      for (final day in const [
                        '日',
                        '月',
                        '火',
                        '水',
                        '木',
                        '金',
                        '土',
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(child: Text(day)),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: GestureDetector(
                      key: const Key('calendar_month_grid'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => _horizontalDragDistance = 0,
                      onHorizontalDragUpdate: (details) =>
                          _horizontalDragDistance += details.delta.dx,
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (_horizontalDragDistance.abs() >= 50 ||
                            velocity.abs() >= 300) {
                          final direction = _horizontalDragDistance.abs() >= 50
                              ? _horizontalDragDistance
                              : velocity;
                          _moveMonth(direction < 0 ? 1 : -1);
                        }
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final minHeight =
                              16 +
                              MediaQuery.textScalerOf(context).scale(14) * 1.4 +
                              MediaQuery.textScalerOf(context).scale(11) *
                                  1.4 *
                                  4;
                          final rowHeight = math.max(
                            constraints.maxHeight / rows,
                            minHeight,
                          );
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                for (var row = 0; row < rows; row++)
                                  SizedBox(
                                    height: rowHeight,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (
                                          var column = 0;
                                          column < 7;
                                          column++
                                        )
                                          Expanded(
                                            child: Builder(
                                              builder: (context) {
                                                final day =
                                                    row * 7 +
                                                    column -
                                                    firstOffset +
                                                    1;
                                                if (day < 1 || day > days) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .outlineVariant,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                final date = DateTime(
                                                  month.year,
                                                  month.month,
                                                  day,
                                                );
                                                final events = state
                                                    .eventsForDay(date);
                                                final selected =
                                                    date == state.selectedDate;
                                                return Semantics(
                                                  selected: selected,
                                                  button: true,
                                                  label:
                                                      '${calendarDateText(date)}、予定${events.length}件${selected ? '、再タップで予定一覧' : ''}',
                                                  child: Material(
                                                    color: selected
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .primaryContainer
                                                              .withValues(
                                                                alpha: .35,
                                                              )
                                                        : Colors.transparent,
                                                    child: InkWell(
                                                      key: Key(
                                                        'calendar_day_${month.year}_${month.month}_$day',
                                                      ),
                                                      onTap: state.isSaving
                                                          ? null
                                                          : () => _selectDay(
                                                              date,
                                                            ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: selected
                                                                ? Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                : Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .outlineVariant,
                                                            width: selected
                                                                ? 2
                                                                : 1,
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Text(
                                                              '$day',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            for (final event
                                                                in events.take(
                                                                  3,
                                                                ))
                                                              Builder(
                                                                builder: (context) {
                                                                  final label = state
                                                                      .labels
                                                                      .where(
                                                                        (
                                                                          label,
                                                                        ) =>
                                                                            label.id ==
                                                                            event.labelId,
                                                                      )
                                                                      .firstOrNull;
                                                                  final color =
                                                                      label ==
                                                                          null
                                                                      ? Theme.of(
                                                                          context,
                                                                        ).colorScheme.surfaceContainerHighest
                                                                      : calendarLabelColor(
                                                                          label
                                                                              .color,
                                                                        );
                                                                  return Padding(
                                                                    padding:
                                                                        const EdgeInsets.only(
                                                                          top:
                                                                              2,
                                                                        ),
                                                                    child: Semantics(
                                                                      label:
                                                                          '${event.title}、${label?.name ?? '色ラベルを確認してください'}',
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              2,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color:
                                                                              color,
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                3,
                                                                              ),
                                                                        ),
                                                                        child: Text(
                                                                          event
                                                                              .title,
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                11,
                                                                            height:
                                                                                1.4,
                                                                            color:
                                                                                color.computeLuminance() > .179
                                                                                ? Colors.black
                                                                                : Colors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            if (events.length >
                                                                3)
                                                              Text(
                                                                '他${events.length - 3}件',
                                                                maxLines: 1,
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      height:
                                                                          1.4,
                                                                    ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                tooltip: '予定を追加',
                shape: const CircleBorder(),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: .85),
                onPressed: canEdit ? () => _edit() : null,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
