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
    final state = ref.watch(calendarNotificationsNotifierProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('予定の端末通知'),
      subtitle: Text(
        state.isSyncing
            ? '通知予約を更新中'
            : switch (state.status) {
                CalendarNotificationStatus.ready => '通知予約を更新しました（最大4週間先まで）',
                CalendarNotificationStatus.denied => '通知権限がありません',
                _ => '通知予約を更新できませんでした。再試行してください',
              },
      ),
      trailing: TextButton(
        onPressed: state.isSyncing
            ? null
            : () => state.status == CalendarNotificationStatus.denied
                  ? ref
                        .read(calendarNotificationsNotifierProvider.notifier)
                        .requestPermission()
                  : ref
                        .read(calendarNotificationsNotifierProvider.notifier)
                        .refresh(),
        child: Text(
          state.status == CalendarNotificationStatus.denied ? '通知を許可' : '再試行',
        ),
      ),
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
      title: const Text('予定の通知設定'),
      subtitle: const Text('終日の基準時刻・デフォルト通知'),
      trailing: const Icon(Icons.edit),
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
  @override
  Widget build(BuildContext context) => AlertDialog(
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
              title: const Text('終日の通知基準時刻（この端末）'),
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
            const Text('デフォルトの変更は新規予定と終日・時間指定の切替時に適用します。'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
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
  );
}
