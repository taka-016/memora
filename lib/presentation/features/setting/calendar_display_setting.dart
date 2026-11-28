import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_display_settings_notifier.dart';

class CalendarDisplaySetting extends HookConsumerWidget {
  const CalendarDisplaySetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionRevision = useState(0);
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
          trailing: KeyedSubtree(
            key: const Key('calendar_week_start_setting'),
            child: DropdownMenu<CalendarWeekStart>(
              width: 150,
              selectOnly: true,
              menuStyle: const MenuStyle(
                alignment: AlignmentDirectional.bottomStart,
              ),
              requestFocusOnTap: false,
              key: ValueKey(selectionRevision.value),
              initialSelection: value.settings.weekStart,
              dropdownMenuEntries: const [
                DropdownMenuEntry(
                  value: CalendarWeekStart.sunday,
                  label: '日曜日',
                ),
                DropdownMenuEntry(
                  value: CalendarWeekStart.monday,
                  label: '月曜日',
                ),
              ],
              enabled: !value.isSaving,
              onSelected: (day) async {
                selectionRevision.value++;
                if (day != null) {
                  await save(value.settings.copyWith(weekStart: day));
                }
              },
            ),
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
