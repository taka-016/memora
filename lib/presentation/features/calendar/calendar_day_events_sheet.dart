import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/features/calendar/calendar_swipe_pager.dart';

class CalendarDayEventsSheet extends ConsumerStatefulWidget {
  const CalendarDayEventsSheet({
    super.key,
    required this.groupId,
    required this.date,
    required this.onEdit,
    required this.onAdd,
  });
  final String groupId;
  final DateTime date;
  final ValueChanged<CalendarEventDto> onEdit;
  final VoidCallback onAdd;

  @override
  ConsumerState<CalendarDayEventsSheet> createState() =>
      _CalendarDayEventsSheetState();
}

class _CalendarDayEventsSheetState
    extends ConsumerState<CalendarDayEventsSheet> {
  static final _firstDay = DateTime.utc(1);
  static final _dayCount =
      DateTime.utc(9999, 12, 31).difference(_firstDay).inDays + 1;
  late final _pageController = PageController(
    initialPage: DateTime.utc(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    ).difference(_firstDay).inDays,
    keepPage: false,
  );

  DateTime _dateForIndex(int index) {
    final date = _firstDay.add(Duration(days: index));
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarNotifierProvider(widget.groupId));
    final canEdit =
        !state.isSaving && !state.isLoading && state.loadError.isEmpty;
    return PopScope(
      canPop: !state.isSaving,
      child: FractionallySizedBox(
        heightFactor: 1,
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              CalendarSwipePager(
                key: const Key('calendar_day_events_pager'),
                controller: _pageController,
                itemCount: _dayCount,
                onPageChanged: (index) => ref
                    .read(calendarNotifierProvider(widget.groupId).notifier)
                    .selectDate(_dateForIndex(index)),
                itemBuilder: (context, index) {
                  final date = _dateForIndex(index);
                  final events = state.eventsForDay(date);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${calendarDateText(date)}の予定',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              tooltip: '予定一覧を閉じる',
                              onPressed: state.isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      if (state.isLoading) const LinearProgressIndicator(),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                          children: [
                            if (!state.isLoading &&
                                state.loadError.isEmpty &&
                                events.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('この日の予定はありません'),
                              ),
                            if (state.loadError.isNotEmpty)
                              Text(state.loadError),
                            for (final event in events)
                              Builder(
                                builder: (context) {
                                  final label = state.labels
                                      .where(
                                        (label) => label.id == event.labelId,
                                      )
                                      .firstOrNull;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.circle,
                                      color: label == null
                                          ? null
                                          : calendarLabelColor(label.color),
                                    ),
                                    title: Container(
                                      decoration: BoxDecoration(
                                        color: event.isAllDay && label != null
                                            ? calendarLabelColor(label.color)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        event.title,
                                        style: TextStyle(
                                          color: label == null
                                              ? null
                                              : calendarLabelColor(
                                                  event.isAllDay
                                                      ? label.textColor
                                                      : label.color,
                                                ),
                                        ),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(label?.name ?? '色ラベルを確認してください'),
                                        Text(calendarPeriodText(event)),
                                      ],
                                    ),
                                    onTap: canEdit
                                        ? () => widget.onEdit(event)
                                        : null,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  tooltip: 'この日に予定を追加',
                  shape: const CircleBorder(),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: .85),
                  onPressed: canEdit ? widget.onAdd : null,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
