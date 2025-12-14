import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/core/app_logger.dart';

enum GroupListState { loading, groupList, empty, error }

class GroupList extends HookConsumerWidget {
  final MemberDto member;
  final void Function(GroupDto)? onGroupSelected;

  const GroupList({super.key, required this.member, this.onGroupSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getGroupsWithMembersUsecase = ref.read(
      getGroupsWithMembersUsecaseProvider,
    );

    final state = useState(GroupListState.loading);
    final groupsWithMembers = useState<List<GroupDto>>(<GroupDto>[]);
    final errorMessage = useState('');

    final loadData = useCallback(() async {
      try {
        state.value = GroupListState.loading;
        final fetchedGroups = await getGroupsWithMembersUsecase.execute(member);

        if (!context.mounted) return;

        groupsWithMembers.value = fetchedGroups;
        state.value = fetchedGroups.isEmpty
            ? GroupListState.empty
            : GroupListState.groupList;
      } catch (e, stack) {
        logger.e(
          'GroupList._loadData: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (!context.mounted) return;
        errorMessage.value = 'エラーが発生しました';
        state.value = GroupListState.error;
      }
    }, [context, getGroupsWithMembersUsecase, member]);

    useEffect(() {
      Future.microtask(loadData);
      return null;
    }, [loadData]);

    Widget buildContentByState() {
      switch (state.value) {
        case GroupListState.loading:
          return const Center(child: CircularProgressIndicator());
        case GroupListState.empty:
          return const Center(
            child: Text('グループがありません', style: TextStyle(fontSize: 18)),
          );
        case GroupListState.groupList:
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'グループ一覧',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        case GroupListState.error:
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(errorMessage.value, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: loadData, child: const Text('再読み込み')),
              ],
            ),
          );
      }
    }

    return Container(
      key: const Key('group_list'),
      child: buildContentByState(),
    );
  }
}
