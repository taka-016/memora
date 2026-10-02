import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = calendarNotifierProvider(widget.groupId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final month = state.month;
    final firstOffset = month.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    Future<void> edit([CalendarEventDto? event]) async {
      if (state.labels.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => CalendarLabelsDialog(groupId: widget.groupId),
        );
        if (!context.mounted || ref.read(provider).labels.isEmpty) return;
      }
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => CalendarEventDialog(
          groupId: widget.groupId,
          date: ref.read(provider).selectedDate,
          event: event,
        ),
      );
    }

    final selected = state.eventsForDay(state.selectedDate);
    return PopScope(
      canPop: !state.isSaving,
      child: ListView(
        key: const Key('calendar_screen'),
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'グループ選択へ戻る',
                onPressed: state.isSaving ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                '${widget.groupName}のカレンダー',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                tooltip: '再読み込み',
                onPressed: state.isLoading || state.isSaving
                    ? null
                    : notifier.load,
                icon: const Icon(Icons.refresh),
              ),
              TextButton(
                onPressed:
                    state.isSaving ||
                        state.isLoading ||
                        state.loadError.isNotEmpty
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (context) =>
                            CalendarLabelsDialog(groupId: widget.groupId),
                      ),
                child: const Text('色ラベルの設定'),
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
                    : () => notifier.selectDate(
                        DateTime(month.year, month.month - 1),
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${month.year}年${month.month}月',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: '次の月',
                onPressed: month.year == 9999 && month.month == 12
                    ? null
                    : () => notifier.selectDate(
                        DateTime(month.year, month.month + 1),
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          if (state.loadError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(state.loadError),
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
              for (final day in const ['日', '月', '火', '水', '木', '金', '土'])
                Expanded(child: Center(child: Text(day))),
            ],
          ),
          for (var row = 0; row < ((firstOffset + days) / 7).ceil(); row++)
            Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = row * 7 + column - firstOffset + 1;
                        if (day < 1 || day > days) {
                          return const SizedBox(height: 56);
                        }
                        final date = DateTime(month.year, month.month, day);
                        final count = state.eventsForDay(date).length;
                        return Semantics(
                          selected: date == state.selectedDate,
                          label: '${calendarDateText(date)}、予定$count件',
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: date == state.selectedDate
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => notifier.selectDate(date),
                            child: Column(
                              children: [
                                Text('$day'),
                                Text(
                                  count == 0 ? '' : '$count件',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          const Divider(),
          Text(
            '${calendarDateText(state.selectedDate)}の予定',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!state.isLoading && state.loadError.isEmpty && selected.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('この日の予定はありません'),
            ),
          for (final event in selected)
            Builder(
              builder: (context) {
                final label = state.labels
                    .where((label) => label.id == event.labelId)
                    .firstOrNull;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.circle,
                    color: label == null
                        ? null
                        : calendarLabelColor(label.color),
                  ),
                  title: Text(event.title),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label?.name ?? '色ラベルを確認してください'), Text(calendarPeriodText(event))]),
                  onTap:
                      state.isSaving ||
                          state.isLoading ||
                          state.loadError.isNotEmpty
                      ? null
                      : () => edit(event),
                );
              },
            ),
          FilledButton.icon(
            onPressed:
                state.isSaving || state.isLoading || state.loadError.isNotEmpty
                ? null
                : () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('予定を追加'),
          ),
        ],
      ),
    );
  }
}
