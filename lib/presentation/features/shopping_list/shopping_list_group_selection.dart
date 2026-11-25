import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

class ShoppingListGroupSelection extends HookConsumerWidget {
  const ShoppingListGroupSelection({super.key, required this.onSelect});

  final void Function(GroupDto) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupTimelineGroupSelectionNotifierProvider);
    final member = ref.watch(currentMemberNotifierProvider).member;
    final autoSelectedGroup = useRef<String?>(null);
    final groups =
        state.memberId == member?.id &&
            state.status == GroupTimelineGroupSelectionStatus.loaded
        ? state.groups
        : const <GroupDto>[];
    final single = groups.length == 1 ? groups.single : null;
    useEffect(() {
      if (single != null && single.id != autoSelectedGroup.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || ModalRoute.isCurrentOf(context) != true) {
            return;
          }
          autoSelectedGroup.value = single.id;
          onSelect(single);
        });
      }
      return null;
    }, [single?.id]);

    if (member == null ||
        state.memberId != member.id ||
        state.status == GroupTimelineGroupSelectionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == GroupTimelineGroupSelectionStatus.error) {
      return Center(
        child: TextButton(
          onPressed: () => ref
              .read(groupTimelineGroupSelectionNotifierProvider.notifier)
              .load(member),
          child: Text('${state.message}。再試行'),
        ),
      );
    }
    if (groups.isEmpty) {
      return const Center(child: Text('所属グループがありません'));
    }
    return ListView(
      children: [
        for (final group in groups)
          ListTile(
            title: Text(group.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelect(group),
          ),
      ],
    );
  }
}
