import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/group/group_edit_modal.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';

class GroupManagement extends HookConsumerWidget {
  final MemberDto member;

  const GroupManagement({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final data = await getManagedGroupsWithMembersUsecase.execute(member);
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
    }, [member.id]);

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
          ownerId: member.id,
          name: '',
          members: const [],
        );
        final availableMembers = await getManagedMembersUsecase.execute(member);
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
          builder: (dialogContext) => GroupEditModal(
            group: group,
            availableMembers: availableMemberDtos,
            onSave: (createdGroup) async {
              try {
                await createGroupUsecase.execute(createdGroup);
                if (!dialogContext.mounted) {
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
                if (dialogContext.mounted) {
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
        final availableMembers = await getManagedMembersUsecase.execute(member);
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
          builder: (dialogContext) => GroupEditModal(
            group: groupWithMembers,
            availableMembers: availableMemberDtos,
            onSave: (updatedGroup) async {
              try {
                await updateGroupUsecase.execute(updatedGroup);
                if (!dialogContext.mounted) {
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
                if (dialogContext.mounted) {
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

    Widget buildGroupList() {
      return RefreshIndicator(
        onRefresh: loadData,
        child: ListView.builder(
          itemCount: managedGroups.value.length,
          itemBuilder: (context, index) => buildGroupCard(index),
        ),
      );
    }

    Widget buildGroupListContent() {
      return managedGroups.value.isEmpty ? buildEmptyState() : buildGroupList();
    }

    Widget buildContent() {
      if (isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          buildHeader(),
          const Divider(),
          Expanded(child: buildGroupListContent()),
        ],
      );
    }

    return Container(key: const Key('group_settings'), child: buildContent());
  }
}
