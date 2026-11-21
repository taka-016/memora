import 'package:memora/presentation/notifiers/calendar/calendar_event_view_notifier.dart';
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
  late final _viewProvider = calendarEventViewNotifierProvider(
    Object(),
    widget.event,
    series: widget.series,
  );
  String? _urlError;

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
        setState(() => _urlError = null);
        await ref
            .read(_viewProvider.notifier)
            .refreshAfterSave(
              id: result.id,
              start: result.start,
              label: result.label,
            );
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
  Widget build(BuildContext context) {
    final state = ref.watch(_viewProvider);
    final event = state.event;
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定の照会'),
        actions: [
          if (event != null) ...[
            IconButton(
              tooltip: '予定を編集',
              onPressed: () => _edit(event, state.series),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: '予定を複製',
              onPressed: () => _duplicate(event),
              icon: const Icon(Icons.content_copy),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: switch (event) {
          CalendarEventDto() => _details(event, state.savedLabelName),
          null when state.isLoading => const Center(
            child: CircularProgressIndicator(),
          ),
          null when state.hasError => Center(
            child: TextButton(
              onPressed: () => ref.read(_viewProvider.notifier).retry(),
              child: const Text('予定を再取得'),
            ),
          ),
          null => const Center(child: Text('予定が見つかりませんでした')),
        },
      ),
    );
  }

  Widget _details(CalendarEventDto event, String? savedLabelName) {
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
        savedLabelName ??
        (event.labelType == 'group' && groupName != null
            ? '$groupNameの予定'
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
