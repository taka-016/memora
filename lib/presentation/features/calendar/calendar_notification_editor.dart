import 'package:flutter/material.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';

String calendarNotificationText(int value, bool allDay) {
  if (value == 0) return '予定の開始時';
  if (allDay) {
    return value % 10080 == 0 ? '${value ~/ 10080}週間前' : '${value ~/ 1440}日前';
  }
  return value % 60 == 0 ? '${value ~/ 60}時間前' : '$value分前';
}

class CalendarNotificationEditor extends StatelessWidget {
  const CalendarNotificationEditor({
    super.key,
    required this.allDay,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });
  final bool allDay;
  final List<int> values;
  final ValueChanged<List<int>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('通知（${values.length}/$MAX_CALENDAR_NOTIFICATIONS）'),
      if (values.isEmpty) const Text('通知なし'),
      for (final value in values)
        Row(
          children: [
            Expanded(child: Text(calendarNotificationText(value, allDay))),
            IconButton(
              tooltip: '通知を解除',
              onPressed: enabled
                  ? () => onChanged(values.where((v) => v != value).toList())
                  : null,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      TextButton(
        onPressed: !enabled || values.length >= MAX_CALENDAR_NOTIFICATIONS
            ? null
            : () async {
                final choices = allDay
                    ? [0, 1440, 2880, 10080, 20160, 40320]
                    : [0, 5, 10, 15, 30, 60, 120, 180, 1440, 10080];
                final selected = await showDialog<int>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('通知のタイミング'),
                    children: [
                      for (final value in choices.where(
                        (v) => !values.contains(v),
                      ))
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, value),
                          child: Text(calendarNotificationText(value, allDay)),
                        ),
                    ],
                  ),
                );
                if (selected != null) onChanged([...values, selected]);
              },
        child: const Text('通知を追加'),
      ),
    ],
  );
}
