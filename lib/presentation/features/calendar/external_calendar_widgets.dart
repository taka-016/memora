import 'package:memora/presentation/features/calendar/external_calendar_recurrence_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';

class ExternalCalendarSettingsDialog extends ConsumerWidget {
  const ExternalCalendarSettingsDialog({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(externalCalendarNotifierProvider);
    final notifier = ref.read(externalCalendarNotifierProvider.notifier);
    final busy = state.isBusy || state.isLoading;
    return AlertDialog(
      title: const Text('端末カレンダー連携'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('端末のカレンダーの予定を表示します。他のメンバーには共有されません。'),
              if (state.error.isNotEmpty) Text(state.error),
              if (!state.hasPermission)
                TextButton(
                  onPressed: busy ? null : notifier.requestAccess,
                  child: const Text('カレンダーへのアクセスを許可'),
                ),
              if (state.hasPermission)
                TextButton(
                  onPressed: busy ? null : notifier.refresh,
                  child: const Text('カレンダー一覧を更新'),
                ),
              if (state.hasPermission && state.connections.isEmpty)
                const Text('端末に同期されたカレンダーがありません。端末のカレンダー同期設定を確認してください。'),
              for (final connection in state.connections)
                ExpansionTile(
                  key: ValueKey('external_account_${connection.account.id}'),
                  title: Text(connection.account.name),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.failures[connection.account.id]
                        case final failure?)
                      Text(failure.message),
                    const Text('表示対象（変更すると保存されます）'),
                    for (final calendar
                        in state.calendarsByAccount[connection.account.id] ??
                            <ExternalCalendarDto>[])
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(calendar.name),
                        value: connection.calendarIds.contains(calendar.id),
                        onChanged: busy
                            ? null
                            : (value) {
                                final ids = {...connection.calendarIds};
                                if (value == true) {
                                  ids.add(calendar.id);
                                } else {
                                  ids.remove(calendar.id);
                                }
                                notifier.selectCalendars(
                                  connection.account.id,
                                  ids,
                                );
                              },
                      ),
                    for (final id in connection.calendarIds.where(
                      (id) =>
                          !(state.calendarsByAccount[connection.account.id] ??
                                  [])
                              .any((v) => v.id == id),
                    ))
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('利用できないカレンダー: $id'),
                        value: true,
                        onChanged: busy
                            ? null
                            : (_) => notifier.selectCalendars(
                                connection.account.id,
                                {...connection.calendarIds}..remove(id),
                              ),
                      ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => notifier.selectCalendars(
                              connection.account.id,
                              {},
                            ),
                      child: const Text('選択を解除'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

Future<void> showExternalCalendarEvent(
  BuildContext context,
  ExternalCalendarEventDto event, {
  required String sourceLabel,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('端末カレンダーの予定'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title, style: Theme.of(context).textTheme.titleLarge),
          Text(sourceLabel),
          Text(
            calendarPeriodText(
              CalendarEventDto(
                id: '',
                groupId: '',
                title: event.title,
                startDateTime: event.startDateTime,
                endDateTime: event.endDateTime,
                isAllDay: event.isAllDay,
              ),
            ),
          ),
          if (event.isRecurring) ...[
            const Text('繰り返し予定'),
            for (final rule in event.recurrence)
              Text(externalCalendarRecurrenceText(rule)),
            if (event.timeZone != null) Text('タイムゾーン: ${event.timeZone}'),
          ],
          if (event.locationName.isNotEmpty) Text(event.locationName),
          if (event.memo.isNotEmpty) Text(event.memo),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  ),
);
