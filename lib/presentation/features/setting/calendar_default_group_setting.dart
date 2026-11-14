import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

class CalendarDefaultGroupSetting extends ConsumerWidget {
  const CalendarDefaultGroupSetting({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarGroupSettingsNotifierProvider);
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('予定追加時の既定グループ'),
          trailing: SizedBox(
            width: 150,
            child: DropdownButton<String>(
              isExpanded: true,
              value: state.effectiveSettings.defaultGroupId ?? '',
              items: [
                const DropdownMenuItem(value: '', child: Text('未設定')),
                for (final group in state.groups)
                  DropdownMenuItem(
                    value: group.id,
                    child: Text(group.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged:
                  !state.canUseSettings || state.isSaving || !state.groupsReady
                  ? null
                  : (id) async {
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
