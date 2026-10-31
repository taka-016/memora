import 'package:memora/presentation/shared/dialogs/edit_discard_scope.dart';
import 'package:memora/composition_root/providers/calendar_notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/presentation/features/calendar/calendar_notification_editor.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notification_preferences_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';

class CalendarNotificationStatusView extends ConsumerWidget {
  const CalendarNotificationStatusView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(calendarNotificationsSupportedProvider)) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(calendarNotificationsNotifierProvider);
    final denied = state.status == CalendarNotificationStatus.denied;
    final failed = state.status == CalendarNotificationStatus.failed;
    if (!denied && !failed) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          denied ? '予定の通知が許可されていません' : '予定の通知を設定できませんでした',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          denied
              ? 'スマートフォンの設定で、このアプリの通知をオンにしてください。'
              : '予定で設定した通知が届かない可能性があります。',
        ),
        TextButton(
          onPressed: state.isSyncing
              ? null
              : () => denied
                    ? ref
                          .read(calendarNotificationsNotifierProvider.notifier)
                          .openNotificationSettings()
                    : ref
                          .read(calendarNotificationsNotifierProvider.notifier)
                          .retry(),
          child: Text(
            state.isSyncing
                ? (denied ? '設定を開いています…' : '設定中…')
                : denied
                ? 'スマートフォンの設定を開く'
                : '通知を設定し直す',
          ),
        ),
      ],
    );
  }
}

class CalendarNotificationSetting extends ConsumerWidget {
  const CalendarNotificationSetting({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(calendarNotificationPreferencesNotifierProvider);
    if (value.value == null) {
      return value.hasError
          ? TextButton(
              onPressed: () => ref.invalidate(
                calendarNotificationPreferencesNotifierProvider,
              ),
              child: const Text('通知設定を再取得'),
            )
          : const LinearProgressIndicator();
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text('予定の通知設定')),
          SizedBox(width: 8),
          Icon(Icons.edit, size: 20),
        ],
      ),
      onTap: value.value!.isSaving
          ? null
          : () async {
              final result = await showDialog<CalendarNotificationPreferences>(
                context: context,
                builder: (context) =>
                    _NotificationSettingsDialog(value.value!.preferences),
              );
              if (result == null || !context.mounted) return;
              final saved = await ref
                  .read(
                    calendarNotificationPreferencesNotifierProvider.notifier,
                  )
                  .save(result);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(saved ? '通知設定を保存しました' : '通知設定を保存できませんでした'),
                  ),
                );
              }
            },
    );
  }
}

class _NotificationSettingsDialog extends StatefulWidget {
  const _NotificationSettingsDialog(this.initial);
  final CalendarNotificationPreferences initial;
  @override
  State<_NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<_NotificationSettingsDialog> {
  late int _minute = widget.initial.allDayMinuteOfDay;
  late List<int> _allDay = widget.initial.allDay;
  late List<int> _timed = widget.initial.timed;
  bool get _isDirty =>
      _minute != widget.initial.allDayMinuteOfDay ||
      _allDay.join(',') != widget.initial.allDay.join(',') ||
      _timed.join(',') != widget.initial.timed.join(',');
  @override
  Widget build(BuildContext context) => EditDiscardScope(
    isDirty: _isDirty,
    child: AlertDialog(
      title: const Text('予定の通知設定'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('終日の通知基準時刻'),
                subtitle: Text(
                  '${(_minute ~/ 60).toString().padLeft(2, '0')}:${(_minute % 60).toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: _minute ~/ 60,
                      minute: _minute % 60,
                    ),
                  );
                  if (time != null && mounted) {
                    setState(() => _minute = time.hour * 60 + time.minute);
                  }
                },
              ),
              const Text('終日のデフォルト'),
              CalendarNotificationEditor(
                allDay: true,
                values: _allDay,
                onChanged: (v) => setState(() => _allDay = v),
              ),
              const Text('時間指定のデフォルト'),
              CalendarNotificationEditor(
                allDay: false,
                values: _timed,
                onChanged: (v) => setState(() => _timed = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.maybePop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            CalendarNotificationPreferences(
              allDayMinuteOfDay: _minute,
              allDay: _allDay,
              timed: _timed,
            ),
          ),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}
