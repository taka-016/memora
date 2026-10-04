import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

class CalendarNavigationView extends HookConsumerWidget {
  const CalendarNavigationView({super.key, this.groupId});
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(groupTimelineGroupSelectionNotifierProvider);
    final member = ref.watch(currentMemberNotifierProvider).member;
    final autoSelected = useState<String?>(null);
    final groups = selection.groups;
    final loaded =
        member != null &&
        selection.memberId == member.id &&
        selection.status == GroupTimelineGroupSelectionStatus.loaded;
    final autoSelect =
        loaded &&
        groupId == null &&
        groups.length == 1 &&
        autoSelected.value != groups.single.id;
    final group = loaded
        ? groups.where((group) => group.id == groupId).firstOrNull
        : null;
    useEffect(() {
      if (autoSelect) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          autoSelected.value = groups.single.id;
          CalendarRoute(groupId: groups.single.id).go(context);
        });
      } else if (loaded && groupId != null && group == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          const CalendarGroupListRoute().go(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('指定されたグループが見つかりませんでした')));
        });
      }
      return null;
    }, [autoSelect, loaded, groupId, group]);

    if (member == null ||
        selection.memberId != member.id ||
        selection.status == GroupTimelineGroupSelectionStatus.loading ||
        autoSelect) {
      return const Center(child: CircularProgressIndicator());
    }
    if (selection.status == GroupTimelineGroupSelectionStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selection.message),
            TextButton(
              onPressed: () => ref
                  .read(groupTimelineGroupSelectionNotifierProvider.notifier)
                  .load(member),
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }
    if (groupId != null) {
      if (group == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return CalendarScreen(
        key: ValueKey(group.id),
        groupId: group.id,
        groupName: group.name,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const CalendarGroupListRoute().go(context);
          }
        },
      );
    }
    return Column(
      key: const Key('calendar_group_list'),
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'グループを選択',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(groupTimelineGroupSelectionNotifierProvider.notifier)
                .load(member),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (groups.isEmpty) const ListTile(title: Text('グループがありません')),
                for (final group in groups)
                  ListTile(
                    title: Text(group.name),
                    subtitle: Text('${group.members.length}人のメンバー'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => CalendarRoute(groupId: group.id).go(context),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
