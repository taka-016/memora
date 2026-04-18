import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';

enum GroupSelectionListState { loading, groupList, empty, error }

class GroupSelectionList extends HookConsumerWidget {
  final void Function(GroupDto)? onGroupSelected;
  final String title;
  final Key listKey;
  final Future<List<GroupDto>>? groupsFuture;
  final VoidCallback? onRetry;

  const GroupSelectionList({
    super.key,
    this.onGroupSelected,
    this.title = 'グループ一覧',
    this.listKey = const Key('group_list'),
    this.groupsFuture,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final getGroupsWithMembersUsecase = ref.read(
      getGroupsWithMembersUsecaseProvider,
    );

    final state = useState(GroupSelectionListState.loading);
    final groupsWithMembers = useState<List<GroupDto>>(<GroupDto>[]);
    final errorMessage = useState('');
    final latestRequestedFuture = useRef<Future<List<GroupDto>>?>(null);

    final loadData = useCallback(() async {
      final requestedFuture =
          groupsFuture ?? getGroupsWithMembersUsecase.execute(currentMember);
      latestRequestedFuture.value = requestedFuture;

      try {
        state.value = GroupSelectionListState.loading;
        errorMessage.value = '';
        final resolvedGroups = await requestedFuture;

        if (!context.mounted ||
            latestRequestedFuture.value != requestedFuture) {
          return;
        }

        groupsWithMembers.value = resolvedGroups;
        state.value = resolvedGroups.isEmpty
            ? GroupSelectionListState.empty
            : GroupSelectionListState.groupList;
      } catch (e, stack) {
        if (!context.mounted ||
            latestRequestedFuture.value != requestedFuture) {
          return;
        }
        logger.e(
          'GroupSelectionList._loadData: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        errorMessage.value = 'エラーが発生しました';
        state.value = GroupSelectionListState.error;
      }
    }, [context, currentMember, getGroupsWithMembersUsecase, groupsFuture]);

    useEffect(() {
      Future.microtask(loadData);
      return null;
    }, [loadData]);

    Widget buildContentByState() {
      switch (state.value) {
        case GroupSelectionListState.loading:
          return const Center(child: CircularProgressIndicator());
        case GroupSelectionListState.empty:
          return const Center(
            child: Text('グループがありません', style: TextStyle(fontSize: 18)),
          );
        case GroupSelectionListState.groupList:
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: groupsWithMembers.value.length,
                  itemBuilder: (context, index) {
                    final group = groupsWithMembers.value[index];
                    return ListTile(
                      title: Text(group.name),
                      subtitle: Text('${group.members.length}人のメンバー'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => onGroupSelected?.call(group),
                    );
                  },
                ),
              ),
            ],
          );
        case GroupSelectionListState.error:
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(errorMessage.value, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (onRetry != null && groupsFuture != null) {
                      state.value = GroupSelectionListState.loading;
                      errorMessage.value = '';
                      onRetry?.call();
                      return;
                    }
                    loadData();
                  },
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
      }
    }

    return Container(key: listKey, child: buildContentByState());
  }
}
