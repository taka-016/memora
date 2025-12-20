import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/group/group_edit_modal.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';

class GroupManagement extends HookConsumerWidget {
  const GroupManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final getManagedGroupsWithMembersUsecase = ref.read(
      getManagedGroupsWithMembersUsecaseProvider,
    );
    final deleteGroupUsecase = ref.read(deleteGroupUsecaseProvider);
    final createGroupUsecase = ref.read(createGroupUsecaseProvider);
    final updateGroupUsecase = ref.read(updateGroupUsecaseProvider);
    final getManagedMembersUsecase = ref.read(getManagedMembersUsecaseProvider);

    final managedGroups = useState<List<GroupDto>>([]);
    final isLoading = useState(true);

    Future<void> loadData() async {
      isLoading.value = true;

      try {
        final data = await getManagedGroupsWithMembersUsecase.execute(
          currentMember,
        );
        managedGroups.value = List<GroupDto>.from(data);
      } catch (e, stack) {
        logger.e(
          'GroupManagement.loadData: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('データの読み込みに失敗しました: $e')));
        }
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    useEffect(() {
      loadData();
      return null;
    }, [currentMember.id]);

    Future<void> deleteGroup(GroupDto groupWithMembers) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await deleteGroupUsecase.execute(groupWithMembers.id);
        if (!context.mounted) {
          return;
        }
        await loadData();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('グループを削除しました')),
        );
      } catch (e, stack) {
        logger.e(
          'GroupManagement.deleteGroup: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }

    Future<void> showDeleteConfirmDialog(GroupDto groupWithMembers) async {
      await DeleteConfirmDialog.show(
        context,
        title: 'グループ削除',
        content: '${groupWithMembers.name}を削除しますか？',
        onConfirm: () => deleteGroup(groupWithMembers),
      );
    }

    Future<void> showAddGroupDialog() async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final group = GroupDto(
          id: '',
          ownerId: currentMember.id,
          name: '',
          members: const [],
        );
        final availableMembers = await getManagedMembersUsecase.execute(
          currentMember,
        );
        final availableMemberDtos = GroupMemberMapper.fromMemberList(
          availableMembers,
          group.id,
        );

        if (!context.mounted) {
          return;
        }

        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (_) => GroupEditModal(
            group: group,
            availableMembers: availableMemberDtos,
            member: GroupMemberMapper.fromMember(currentMember, group.id),
            onSave: (createdGroup) async {
              try {
                await createGroupUsecase.execute(createdGroup);
                if (!context.mounted) {
                  return;
                }
                await loadData();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('グループを作成しました')),
                );
              } catch (e, stack) {
                logger.e(
                  'GroupManagement.showAddGroupDialog.onSave: ${e.toString()}',
                  error: e,
                  stackTrace: stack,
                );
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('作成に失敗しました: $e')),
                  );
                }
              }
            },
          ),
        );
      } catch (e, stack) {
        logger.e(
          'GroupManagement.showAddGroupDialog: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('メンバー情報の取得に失敗しました: $e')));
        }
      }
    }

    Future<void> showEditGroupDialog(GroupDto groupWithMembers) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final availableMembers = await getManagedMembersUsecase.execute(
          currentMember,
        );
        final availableMemberDtos = GroupMemberMapper.fromMemberList(
          availableMembers,
          groupWithMembers.id,
        );
        if (!context.mounted) {
          return;
        }

        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (_) => GroupEditModal(
            group: groupWithMembers,
            availableMembers: availableMemberDtos,
            member: GroupMemberMapper.fromMember(
              currentMember,
              groupWithMembers.id,
            ),
            onSave: (updatedGroup) async {
              try {
                await updateGroupUsecase.execute(updatedGroup);
                if (!context.mounted) {
                  return;
                }
                await loadData();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('グループを更新しました')),
                );
              } catch (e, stack) {
                logger.e(
                  'GroupManagement.showEditGroupDialog.onSave: ${e.toString()}',
                  error: e,
                  stackTrace: stack,
                );
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('更新に失敗しました: $e')),
                  );
                }
              }
            },
          ),
        );
      } catch (e, stack) {
        logger.e(
          'GroupManagement.showEditGroupDialog: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('メンバー情報の取得に失敗しました: $e')));
        }
      }
    }

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Text(
              'グループ管理',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: showAddGroupDialog,
              icon: const Icon(Icons.add),
              label: const Text('グループ追加'),
            ),
          ],
        ),
      );
    }

    Widget buildEmptyState() {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_work, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '管理しているグループがありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'グループを追加してください',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    Widget buildGroupCard(int index) {
      final groupWithMembers = managedGroups.value[index];

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(groupWithMembers.name.substring(0, 1)),
          ),
          title: Text(groupWithMembers.name),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => showDeleteConfirmDialog(groupWithMembers),
          ),
          onTap: () => showEditGroupDialog(groupWithMembers),
        ),
      );
    }

    Widget buildGroupListView() {
      return ListView.builder(
        itemCount: managedGroups.value.length,
        itemBuilder: (context, index) => buildGroupCard(index),
      );
    }

    Widget buildGroupListContent() {
      if (managedGroups.value.isEmpty) {
        return buildEmptyState();
      }
      return RefreshIndicator(onRefresh: loadData, child: buildGroupListView());
    }

    Widget buildLoadingState() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildBody() {
      if (isLoading.value) {
        return buildLoadingState();
      }

      return Column(
        children: [
          buildHeader(),
          const Divider(),
          Expanded(child: buildGroupListContent()),
        ],
      );
    }

    return Container(key: const Key('group_settings'), child: buildBody());
  }
}
