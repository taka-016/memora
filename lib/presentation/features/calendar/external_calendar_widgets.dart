import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';

class ExternalCalendarStatus extends ConsumerWidget {
  const ExternalCalendarStatus({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(externalCalendarNotifierProvider);
    final notifier = ref.read(externalCalendarNotifierProvider.notifier);
    if (state.connection == null && state.error.isEmpty && !state.isBusy) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (state.isLoading || state.isBusy) const LinearProgressIndicator(semanticsLabel: 'Googleカレンダーを取得中'),
        if (state.error.isNotEmpty) Text(state.error),
        if (state.isStale) const Text('最新の情報を取得できていません。前回のGoogle予定を表示しています'),
        Wrap(children: [
          TextButton(onPressed: state.isLoading || state.isBusy ? null : notifier.refresh, child: const Text('Google予定を再取得')),
          if (state.needsAuthentication)
            TextButton(onPressed: state.isBusy ? null : notifier.connect, child: const Text('Googleカレンダーを再認証')),
        ]),
      ]),
    );
  }
}

class ExternalCalendarSettingsDialog extends ConsumerWidget {
  const ExternalCalendarSettingsDialog({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(externalCalendarNotifierProvider);
    final notifier = ref.read(externalCalendarNotifierProvider.notifier);
    final connection = state.connection;
    final busy = state.isBusy || state.isLoading;
    final missing = connection?.calendarIds.where((id) => !state.calendars.any((calendar) => calendar.id == id)) ?? const <String>[];
    return AlertDialog(
      title: const Text('Googleカレンダー連携'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('自分のGoogle予定をこの端末だけで表示します。他のメンバーには共有されません。予定の変更はGoogleカレンダーで行ってください。'),
          if (connection != null) Text(connection.account.email),
          if (busy) const LinearProgressIndicator(),
          if (state.error.isNotEmpty) Text(state.error),
          if (state.needsAuthentication) TextButton(onPressed: busy ? null : notifier.connect, child: const Text('Googleカレンダーを再認証')),
          if (connection == null)
            TextButton(onPressed: busy ? null : notifier.connect, child: const Text('Googleアカウントを選択して連携')),
          if (connection != null) ...[
            const Text('表示対象（変更すると保存されます）'),
            for (final calendar in state.calendars)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(calendar.name),
                value: connection.calendarIds.contains(calendar.id),
                onChanged: busy ? null : (value) {
                  final ids = {...connection.calendarIds};
                  if (value == true) { ids.add(calendar.id); } else { ids.remove(calendar.id); }
                  notifier.selectCalendars(ids);
                },
              ),
            for (final id in missing)
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: Text('利用できないカレンダー: $id'), value: true,
                onChanged: busy ? null : (_) => notifier.selectCalendars({...connection.calendarIds}..remove(id))),
            TextButton(onPressed: busy ? null : notifier.refresh, child: const Text('カレンダー一覧を再取得')),
            TextButton(onPressed: busy ? null : notifier.connect, child: const Text('Googleアカウントを変更')),
            TextButton(onPressed: busy ? null : notifier.disconnect, child: const Text('連携を解除')),
          ],
        ])),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
    );
  }
}

Future<void> showExternalCalendarEvent(BuildContext context, ExternalCalendarEventDto event) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Googleカレンダーの予定（読み取り専用）'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(event.title, style: Theme.of(context).textTheme.titleLarge),
      Text('Google · ${event.calendarName}'),
      Text(calendarPeriodText(CalendarEventDto(id: '', groupId: '', title: event.title, startDateTime: event.startDateTime, endDateTime: event.endDateTime, isAllDay: event.isAllDay))),
      if (event.isRecurring) const Text('繰り返し予定'),
      if (event.locationName.isNotEmpty) Text(event.locationName),
      if (event.memo.isNotEmpty) Text(event.memo),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
  ),
);
