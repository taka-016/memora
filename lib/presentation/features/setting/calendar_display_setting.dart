import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_display_settings_notifier.dart';

class CalendarDisplaySetting extends ConsumerWidget {
  const CalendarDisplaySetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(calendarDisplaySettingsNotifierProvider);
    final value = setting.value;
    if (value == null) {
      if (setting.hasError) {
        return TextButton(
          onPressed: () =>
              ref.invalidate(calendarDisplaySettingsNotifierProvider),
          child: const Text('カレンダーの表示設定を再取得'),
        );
      }
      return const LinearProgressIndicator();
    }
    Future<void> save(CalendarDisplaySettings settings) async {
      final success = await ref
          .read(calendarDisplaySettingsNotifierProvider.notifier)
          .save(settings);
      if (!context.mounted || success) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('カレンダーの表示設定を反映できませんでした')));
    }

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('週の始まり'),
          trailing: DropdownButton<CalendarWeekStart>(
            key: const Key('calendar_week_start_setting'),
            value: value.settings.weekStart,
            items: const [
              DropdownMenuItem(
                value: CalendarWeekStart.sunday,
                child: Text('日曜日'),
              ),
              DropdownMenuItem(
                value: CalendarWeekStart.monday,
                child: Text('月曜日'),
              ),
            ],
            onChanged: value.isSaving
                ? null
                : (day) async {
                    if (day != null)
                      await save(value.settings.copyWith(weekStart: day));
                  },
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('六曜を表示'),
          value: value.settings.showRokuyo,
          onChanged: value.isSaving
              ? null
              : (show) => save(value.settings.copyWith(showRokuyo: show)),
        ),
      ],
    );
  }
}
