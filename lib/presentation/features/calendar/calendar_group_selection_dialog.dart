import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

class CalendarGroupSelectionDialog extends ConsumerStatefulWidget {
  const CalendarGroupSelectionDialog({super.key});
  @override
  ConsumerState<CalendarGroupSelectionDialog> createState() =>
      _CalendarGroupSelectionDialogState();
}

class _CalendarGroupSelectionDialogState
    extends ConsumerState<CalendarGroupSelectionDialog> {
  late final Set<String> _selected = {
    ...ref
        .read(calendarGroupSettingsNotifierProvider)
        .settings
        .visibleGroupIds,
  };
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarGroupSettingsNotifierProvider);
    return AlertDialog(
      title: const Text('表示グループの選択'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isLoading) const LinearProgressIndicator(),
              if (!state.groupsReady)
                TextButton(
                  onPressed: () {
                    final member = ref
                        .read(currentMemberNotifierProvider)
                        .member;
                    if (member != null) {
                      ref
                          .read(
                            groupTimelineGroupSelectionNotifierProvider
                                .notifier,
                          )
                          .load(member);
                    }
                  },
                  child: const Text('所属グループを再取得'),
                ),
              if (state.groupsReady && state.groups.isEmpty)
                const Text('グループを作成するか、グループに参加してください'),
              for (final group in state.groups)
                CheckboxListTile(
                  title: Text(group.name),
                  value: _selected.contains(group.id),
                  onChanged: !state.groupsReady || state.isSaving
                      ? null
                      : (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(group.id);
                          } else {
                            _selected.remove(group.id);
                          }
                        }),
                ),
              if (state.error.isNotEmpty) Text(state.error),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : () => setState(_selected.clear),
          child: const Text('全解除'),
        ),
        TextButton(
          onPressed: state.isSaving ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed:
              !state.groupsReady || !state.canUseSettings || state.isSaving
              ? null
              : () async {
                  final success = await ref
                      .read(calendarGroupSettingsNotifierProvider.notifier)
                      .setVisibleGroups(
                        _selected.intersection(
                          state.groups.map((g) => g.id).toSet(),
                        ),
                      );
                  if (success && context.mounted) Navigator.pop(context);
                },
          child: const Text('確定'),
        ),
      ],
    );
  }
}
