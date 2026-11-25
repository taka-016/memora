import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/shared/group_selection/group_selection_list.dart';

class ShoppingListGroupSelection extends HookConsumerWidget {
  const ShoppingListGroupSelection({super.key, required this.onSelect});

  final void Function(GroupDto) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupTimelineGroupSelectionNotifierProvider);
    final member = ref.watch(currentMemberNotifierProvider).member;
    final autoSelectedGroup = useRef<String?>(null);
    final hasCurrentGroupState = member != null && state.memberId == member.id;
    final groups =
        hasCurrentGroupState &&
            state.status == GroupTimelineGroupSelectionStatus.loaded
        ? state.groups
        : null;
    final single = groups?.length == 1 ? groups!.single : null;
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

    final notifier = ref.read(
      groupTimelineGroupSelectionNotifierProvider.notifier,
    );
    return GroupSelectionView(
      groups: groups,
      errorMessage:
          hasCurrentGroupState &&
              state.status == GroupTimelineGroupSelectionStatus.error
          ? state.message
          : null,
      onGroupSelected: onSelect,
      onRetry: () {
        if (member != null) notifier.load(member);
      },
      onRefresh: member == null ? null : () => notifier.refreshSilently(member),
    );
  }
}
