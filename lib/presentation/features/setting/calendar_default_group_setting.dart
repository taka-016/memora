import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

class CalendarDefaultGroupSetting extends HookConsumerWidget {
  const CalendarDefaultGroupSetting({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionRevision = useState(0);
    final state = ref.watch(calendarGroupSettingsNotifierProvider);
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('予定追加時の既定グループ'),
          trailing: SizedBox(
            width: 150,
            child: DropdownMenu<String>(
              key: ValueKey((
                selectionRevision.value,
                state.groups
                    .map((group) => (group.id, group.name))
                    .toList()
                    .toString(),
              )),
              selectOnly: true,
              menuStyle: const MenuStyle(
                alignment: AlignmentDirectional.bottomStart,
              ),
              requestFocusOnTap: false,
              expandedInsets: EdgeInsets.zero,
              initialSelection: state.effectiveSettings.defaultGroupId ?? '',
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: '', label: '未設定'),
                for (final group in state.groups)
                  DropdownMenuEntry(
                    value: group.id,
                    label: group.name,
                    labelWidget: Text(
                      group.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              enabled:
                  !(!state.canUseSettings ||
                      state.isSaving ||
                      !state.groupsReady),
              onSelected: (id) async {
                selectionRevision.value++;
                final success = await ref
                    .read(calendarGroupSettingsNotifierProvider.notifier)
                    .setDefaultGroup(id == '' ? null : id);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('既定グループを保存できませんでした')),
                  );
                }
              },
            ),
          ),
        ),
        if (state.error.isNotEmpty)
          TextButton(
            onPressed: () => ref
                .read(calendarGroupSettingsNotifierProvider.notifier)
                .reload(),
            child: Text(state.error),
          ),
        if (!state.groupsReady)
          TextButton(
            onPressed: () {
              final member = ref.read(currentMemberNotifierProvider).member;
              if (member != null) {
                ref
                    .read(groupTimelineGroupSelectionNotifierProvider.notifier)
                    .load(member);
              }
            },
            child: const Text('所属グループを再取得'),
          ),
      ],
    );
  }
}
