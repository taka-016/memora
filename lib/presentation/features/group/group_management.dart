import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/presentation/features/group/group_edit_modal.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/group_management_notifier.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';

class GroupManagement extends HookConsumerWidget {
  const GroupManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final managementState = ref.watch(groupManagementNotifierProvider);
    final managementNotifier = ref.read(
      groupManagementNotifierProvider.notifier,
    );

    useEffect(() {
      Future.microtask(() => managementNotifier.load(currentMember));
      return null;
    }, [currentMember.id]);

    ref.listen<GroupManagementState>(groupManagementNotifierProvider, (
      previous,
      next,
    ) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final initialLoadFailed =
          previous?.status != next.status &&
          next.status == GroupManagementStatus.error;
      final refreshFailed =
          previous?.refreshStatus != next.refreshStatus &&
          next.refreshStatus == GroupManagementRefreshStatus.error;
      final operationFailed =
          previous?.operationStatus != next.operationStatus &&
          next.operationStatus == GroupManagementOperationStatus.error;

      if (initialLoadFailed || refreshFailed || operationFailed) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(next.errorMessage)),
        );
        return;
      }

      final operationSucceeded =
          previous?.operationStatus != next.operationStatus &&
          next.operationStatus == GroupManagementOperationStatus.success;
      if (!operationSucceeded) {
        return;
      }

      final message = switch (next.operationType) {
        GroupManagementOperationType.create => 'グループを作成しました',
        GroupManagementOperationType.update => 'グループを更新しました',
        GroupManagementOperationType.delete => 'グループを削除しました',
        GroupManagementOperationType.loadAvailableMembers => null,
        null => null,
      };
      if (message != null) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
      }
    });

    Future<void> showDeleteConfirmDialog(GroupDto groupWithMembers) async {
      await DeleteConfirmDialog.show(
        context,
        title: 'グループ削除',
        content: '${groupWithMembers.name}を削除しますか？',
        onConfirm: () => managementNotifier.deleteGroup(groupWithMembers.id),
      );
    }

    Future<void> showAddGroupDialog() async {
      final group = GroupDto(
        id: '',
        ownerId: currentMember.id,
        name: '',
        members: const [],
      );
      final availableMembers = await managementNotifier.loadAvailableMembers(
        group.id,
      );
      if (!context.mounted || availableMembers == null) {
        return;
      }

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => GroupEditModal(
          group: group,
          availableMembers: availableMembers,
          member: GroupMemberMapper.fromMember(currentMember, group.id),
          onSave: managementNotifier.createGroup,
        ),
      );
    }

    Future<void> showEditGroupDialog(GroupDto groupWithMembers) async {
      final availableMembers = await managementNotifier.loadAvailableMembers(
        groupWithMembers.id,
      );
      if (!context.mounted || availableMembers == null) {
        return;
      }

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => GroupEditModal(
          group: groupWithMembers,
          availableMembers: availableMembers,
          member: GroupMemberMapper.fromMember(
            currentMember,
            groupWithMembers.id,
          ),
          onSave: managementNotifier.updateGroup,
        ),
      );
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
      final groupWithMembers = managementState.groups[index];

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
        itemCount: managementState.groups.length,
        itemBuilder: (context, index) => buildGroupCard(index),
      );
    }

    Widget buildGroupListContent() {
      if (managementState.groups.isEmpty) {
        return buildEmptyState();
      }
      return RefreshIndicator(
        onRefresh: managementNotifier.refresh,
        child: buildGroupListView(),
      );
    }

    Widget buildLoadingState() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildBody() {
      if (managementState.status == GroupManagementStatus.initial ||
          managementState.status == GroupManagementStatus.loading) {
        return buildLoadingState();
      }

      final content = managementState.status == GroupManagementStatus.error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('グループ一覧を読み込めませんでした'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => managementNotifier.load(currentMember),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            )
          : buildGroupListContent();

      return Column(
        children: [
          buildHeader(),
          const Divider(),
          Expanded(child: content),
        ],
      );
    }

    return Container(key: const Key('group_settings'), child: buildBody());
  }
}
