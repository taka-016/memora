import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_day_events_sheet.dart';
import 'package:memora/presentation/features/calendar/calendar_month_grid.dart';
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
                    child: CalendarMonthGrid(
                      state: state,
                      onSelectDay: (date) => _selectDay(date),
                      onMoveMonth: _moveMonth,
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
