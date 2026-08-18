import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/presentation/features/group/group_edit_modal.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/group_management_notifier.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';

class GroupManagement extends ConsumerWidget {
  const GroupManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final managementProvider = groupManagementNotifierProvider(currentMember);
    final managementState = ref.watch(managementProvider);
    final managementNotifier = ref.read(managementProvider.notifier);

    ref.listen<AsyncValue<GroupManagementState>>(managementProvider, (
      previous,
      next,
    ) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final loadFailed =
          next.hasError &&
          (!(previous?.hasError ?? false) || previous?.error != next.error);
      if (loadFailed) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: ${next.error}')),
        );
        return;
      }
    });

    Future<bool> runMutation({
      required Future<bool> Function() execute,
      required String successMessage,
      required String failureMessage,
    }) async {
      try {
        final succeeded = await execute();
        if (!context.mounted || !succeeded) {
          return false;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        return true;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$failureMessage: $e')));
        }
        return false;
      }
    }

    Future<void> refreshGroups() async {
      try {
        final refreshStarted = await managementNotifier.refreshGroups();
        if (!refreshStarted) {
          return;
        }
        await ref.read(managementProvider.future);
      } catch (_) {
        // 失敗表示はProviderのAsyncErrorを監視するref.listenで行う。
      }
    }

    Future<void> showDeleteConfirmDialog(GroupDto groupWithMembers) async {
      await DeleteConfirmDialog.show(
        context,
        title: 'グループ削除',
        content: '${groupWithMembers.name}を削除しますか？',
        onConfirm: () async {
          await runMutation(
            execute: () => managementNotifier.deleteGroup(groupWithMembers.id),
            successMessage: 'グループを削除しました',
            failureMessage: '削除に失敗しました',
          );
        },
      );
    }

    Future<void> showAddGroupDialog() async {
      final group = GroupDto(
        id: '',
        ownerId: currentMember.id,
        name: '',
        members: const [],
      );
      late final List<GroupMemberDto>? availableMembers;
      try {
        availableMembers = await managementNotifier.loadAvailableMembers(
          group.id,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('メンバー情報の取得に失敗しました: $e')));
        }
        return;
      }
      if (!context.mounted || availableMembers == null) {
        return;
      }

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => GroupEditModal(
          group: group,
          availableMembers: availableMembers!,
          member: GroupMemberMapper.fromMember(currentMember, group.id),
          onSave: (group) => runMutation(
            execute: () => managementNotifier.createGroup(group),
            successMessage: 'グループを作成しました',
            failureMessage: '作成に失敗しました',
          ),
        ),
      );
    }

    Future<void> showEditGroupDialog(GroupDto groupWithMembers) async {
      late final List<GroupMemberDto>? availableMembers;
      try {
        availableMembers = await managementNotifier.loadAvailableMembers(
          groupWithMembers.id,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('メンバー情報の取得に失敗しました: $e')));
        }
        return;
      }
      if (!context.mounted || availableMembers == null) {
        return;
      }

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => GroupEditModal(
          group: groupWithMembers,
          availableMembers: availableMembers!,
          member: GroupMemberMapper.fromMember(
            currentMember,
            groupWithMembers.id,
          ),
          onSave: (group) => runMutation(
            execute: () => managementNotifier.updateGroup(group),
            successMessage: 'グループを更新しました',
            failureMessage: '更新に失敗しました',
          ),
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
      final groupWithMembers = managementState.requireValue.groups[index];

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
        itemCount: managementState.requireValue.groups.length,
        itemBuilder: (context, index) => buildGroupCard(index),
      );
    }

    Widget buildGroupListContent() {
      if (managementState.requireValue.groups.isEmpty) {
        return buildEmptyState();
      }
      return RefreshIndicator(
        onRefresh: refreshGroups,
        child: buildGroupListView(),
      );
    }

    Widget buildLoadingState() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildBody() {
      if (!managementState.hasValue) {
        if (managementState.hasError) {
          return Column(
            children: [
              buildHeader(),
              const Divider(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('グループ一覧を読み込めませんでした'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: refreshGroups,
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
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
