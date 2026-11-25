import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/core/app_logger.dart';

enum GroupSelectionListState { loading, groupList, empty, error }

class GroupSelectionList extends HookWidget {
  final void Function(GroupDto)? onGroupSelected;
  final String title;
  final Key listKey;
  final Future<List<GroupDto>> groupsFuture;
  final VoidCallback? onRetry;

  const GroupSelectionList({
    super.key,
    this.onGroupSelected,
    this.title = 'グループ一覧',
    this.listKey = const Key('group_list'),
    required this.groupsFuture,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final state = useState(GroupSelectionListState.loading);
    final groupsWithMembers = useState<List<GroupDto>>(<GroupDto>[]);
    final errorMessage = useState('');
    final latestRequestedFuture = useRef<Future<List<GroupDto>>>(groupsFuture);

    final loadData = useCallback(() async {
      final requestedFuture = groupsFuture;
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
    }, [context, groupsFuture]);

    useEffect(() {
      Future.microtask(loadData);
      return null;
    }, [loadData]);

    return Container(
      key: listKey,
      child: GroupSelectionView(
        groups: switch (state.value) {
          GroupSelectionListState.loading ||
          GroupSelectionListState.error => null,
          GroupSelectionListState.empty ||
          GroupSelectionListState.groupList => groupsWithMembers.value,
        },
        errorMessage: state.value == GroupSelectionListState.error
            ? errorMessage.value
            : null,
        title: title,
        onGroupSelected: onGroupSelected,
        onRetry: onRetry ?? loadData,
      ),
    );
  }
}

class GroupSelectionView extends StatelessWidget {
  const GroupSelectionView({
    super.key,
    required this.groups,
    required this.onGroupSelected,
    required this.onRetry,
    this.errorMessage,
    this.onRefresh,
    this.title = 'グループを選択',
    this.listKey,
  });

  final List<GroupDto>? groups;
  final ValueChanged<GroupDto>? onGroupSelected;
  final VoidCallback onRetry;
  final String? errorMessage;
  final RefreshCallback? onRefresh;
  final String title;
  final Key? listKey;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage;
    if (message != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('再読み込み')),
          ],
        ),
      );
    }
    final availableGroups = groups;
    if (availableGroups == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (availableGroups.isEmpty) {
      const empty = Center(
        child: Text('グループがありません', style: TextStyle(fontSize: 18)),
      );
      if (onRefresh == null) return empty;
      return _withRefresh(
        LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: constraints.maxHeight, child: empty)],
          ),
        ),
      );
    }
    return Column(
      key: listKey,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _withRefresh(
            ListView.builder(
              itemCount: availableGroups.length,
              itemBuilder: (context, index) {
                final group = availableGroups[index];
                return ListTile(
                  title: Text(group.name),
                  subtitle: Text('${group.members.length}人のメンバー'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => onGroupSelected?.call(group),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _withRefresh(Widget child) {
    final refresh = onRefresh;
    return refresh == null
        ? child
        : RefreshIndicator(onRefresh: refresh, child: child);
  }
}
