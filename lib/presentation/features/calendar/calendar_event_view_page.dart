import 'package:memora/presentation/features/calendar/calendar_event_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_settings.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/url_launcher_provider.dart';
import 'package:memora/presentation/features/calendar/calendar_event_input_page.dart';
import 'package:memora/presentation/features/calendar/calendar_notification_editor.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/multi_group_calendar_notifier.dart';

class CalendarEventViewPage extends ConsumerStatefulWidget {
  const CalendarEventViewPage({
    super.key,
    required this.date,
    required this.event,
    this.series,
  });

  final DateTime date;
  final CalendarEventDto event;
  final CalendarEventDto? series;

  @override
  ConsumerState<CalendarEventViewPage> createState() =>
      _CalendarEventViewPageState();
}

class _CalendarEventViewPageState extends ConsumerState<CalendarEventViewPage> {
  CalendarEventSaved? _saved;
  Future<({CalendarEventDto event, CalendarEventDto? series})?>? _updatedEvent;
  String? _urlError;

  Future<({CalendarEventDto event, CalendarEventDto? series})?> _loadSavedEvent(
    CalendarEventSaved saved,
  ) async {
    final id = saved.id;
    if (id == null) return null;
    final expander = ref.read(calendarRecurrenceExpanderProvider);
    final event = await ref.read(getCalendarEventByIdProvider)(id);
    if (event == null) return null;
    if (event.recurrenceRule == null) return (event: event, series: null);

    final start = saved.start;
    final nextDay = start.add(const Duration(days: 1));
    final occurrence = expander
        .expand(event, start, nextDay)
        .where((value) => value.startDateTime.isAtSameMomentAs(start))
        .firstOrNull;
    if (occurrence != null) return (event: occurrence, series: event);

    final first = event.startDateTime;
    final firstOccurrence = expander
        .expand(event, first, first.add(const Duration(days: 1)))
        .firstOrNull;
    return (event: firstOccurrence ?? event, series: event);
  }

  Future<void> _edit(CalendarEventDto event, CalendarEventDto? series) async {
    final result = await Navigator.of(context).push<CalendarEventEditResult>(
      MaterialPageRoute(
        builder: (_) => CalendarEventInputPage(
          date: widget.date,
          event: event,
          series: series,
        ),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case CalendarEventDeleted():
        Navigator.of(context).pop(result);
      case CalendarEventSaved():
        setState(() {
          _saved = result;
          _updatedEvent = _loadSavedEvent(result);
          _urlError = null;
        });
      case null:
        break;
    }
  }

  Future<void> _duplicate(CalendarEventDto source) async {
    await Navigator.of(context).pushReplacement<void, CalendarEventDeleted>(
      MaterialPageRoute(
        builder: (_) => CalendarEventInputPage.duplicate(
          date: DateUtils.dateOnly(widget.date),
          source: source,
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    setState(() => _urlError = null);
    final error = await openCalendarEventUrl(url, ref.read(openUrlProvider));
    if (error != null && mounted) setState(() => _urlError = error);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _updatedEvent,
    initialData: (event: widget.event, series: widget.series),
    builder: (context, snapshot) {
      final loading = snapshot.connectionState == ConnectionState.waiting;
      final data = loading ? null : snapshot.data;
      return Scaffold(
        appBar: AppBar(
          title: const Text('予定の照会'),
          actions: [
            if (data != null) ...[
              IconButton(
                tooltip: '予定を編集',
                onPressed:
                    data.series != null &&
                        data.event.originalStartDateTime == null
                    ? null
                    : () => _edit(data.event, data.series),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: '予定を複製',
                onPressed: () => _duplicate(data.event),
                icon: const Icon(Icons.content_copy),
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: switch (data) {
            (event: final event, series: _) => Consumer(
              builder: (context, ref, _) => _details(context, ref, event),
            ),
            null when loading => const Center(
              child: CircularProgressIndicator(),
            ),
            null when snapshot.hasError => Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _updatedEvent = _loadSavedEvent(_saved!);
                }),
                child: const Text('予定を再取得'),
              ),
            ),
            null => const Center(child: Text('予定が見つかりませんでした')),
          },
        ),
      );
    },
  );

  Widget _details(BuildContext context, WidgetRef ref, CalendarEventDto event) {
    final groups = ref.watch(calendarGroupSettingsNotifierProvider).groups;
    final groupName = groups
        .where((group) => group.id == event.groupId)
        .firstOrNull
        ?.name;
    final calendar = ref.watch(
      multiGroupCalendarNotifierProvider.select(
        (state) => state.groups[event.groupId],
      ),
    );
    final label = calendar?.displayLabels
        .where((label) => label.id == event.labelKey)
        .firstOrNull;
    final labelName =
        label?.name ??
        (event.labelType == 'group' && groupName != null
            ? '${groupName}の予定'
            : null);
    final expander = ref.read(calendarRecurrenceExpanderProvider);
    final start = event.timeZone == null
        ? event.startDateTime
        : expander.localTime(event.startDateTime, event.timeZone!);
    final recurrence = CalendarRecurrenceSettings.fromRule(
      event.recurrenceRule,
      start,
      zone: event.timeZone,
      expander: expander,
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(calendarPeriodText(event)),
        const SizedBox(height: 8),
        Text('保存先: ${groupName ?? event.groupId}'),
        if (labelName != null) Text('色ラベル: $labelName'),
        const SizedBox(height: 8),
        Text(recurrence.summary),
        Text(
          event.notificationMinutesBefore.isEmpty
              ? '通知なし'
              : '通知: ${(List.of(event.notificationMinutesBefore)..sort()).map((minutes) => calendarNotificationText(minutes, event.isAllDay)).join('、')}',
        ),
        if (event.locationName.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('場所名'),
          Text(event.locationName),
        ],
        if (event.url.isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(event.url),
            trailing: IconButton(
              tooltip: 'URLを開く',
              onPressed: () => _openUrl(event.url),
              icon: const Icon(Icons.open_in_new),
            ),
            onTap: () => _openUrl(event.url),
          ),
        if (_urlError != null)
          Text(
            _urlError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (event.memo.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('メモ'),
          SelectableText(event.memo),
        ],
      ],
    );
  }
}
