import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../application/usecases/get_managed_groups_usecase.dart';
import '../../application/usecases/delete_group_usecase.dart';
import '../../application/usecases/create_group_usecase.dart';
import '../../application/usecases/get_managed_members_usecase.dart';
import '../../application/usecases/create_group_member_usecase.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/repositories/group_member_repository.dart';
import '../../infrastructure/repositories/firestore_group_repository.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import '../../infrastructure/repositories/firestore_group_member_repository.dart';
import 'group_edit_modal.dart';

class GroupSettings extends StatefulWidget {
  final Member member;
  final GroupRepository? groupRepository;
  final MemberRepository? memberRepository;
  final GroupMemberRepository? groupMemberRepository;

  const GroupSettings({
    super.key,
    required this.member,
    this.groupRepository,
    this.memberRepository,
    this.groupMemberRepository,
  });

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  late final GetManagedGroupsUsecase _getManagedGroupsUsecase;
  late final DeleteGroupUsecase _deleteGroupUsecase;
  late final CreateGroupUsecase _createGroupUsecase;
  late final GetManagedMembersUsecase _getManagedMembersUsecase;
  late final CreateGroupMemberUsecase _createGroupMemberUsecase;

  List<Group> _managedGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 注入されたリポジトリまたはデフォルトのFirestoreリポジトリを使用
    final groupRepository =
        widget.groupRepository ?? FirestoreGroupRepository();
    final memberRepository =
        widget.memberRepository ?? FirestoreMemberRepository();
    final groupMemberRepository =
        widget.groupMemberRepository ?? FirestoreGroupMemberRepository();

    _getManagedGroupsUsecase = GetManagedGroupsUsecase(groupRepository);
    _deleteGroupUsecase = DeleteGroupUsecase(groupRepository);
    _createGroupUsecase = CreateGroupUsecase(groupRepository);
    _getManagedMembersUsecase = GetManagedMembersUsecase(memberRepository);
    _createGroupMemberUsecase = CreateGroupMemberUsecase(groupMemberRepository);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final managedGroups = await _getManagedGroupsUsecase.execute(
        widget.member,
      );
      _managedGroups = managedGroups;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('データの読み込みに失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループ削除'),
        content: Text('${group.name}を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deleteGroupUsecase.execute(group.id);
        if (mounted) {
          await _loadData();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('グループを削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _showGroupEditModal({Group? group}) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 利用可能なメンバーを取得
      final availableMembers = await _getManagedMembersUsecase.execute(
        widget.member,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => GroupEditModal(
          group: group,
          availableMembers: availableMembers,
          onSave: (editedGroup, selectedMemberIds) async {
            try {
              if (group == null) {
                final newGroupId = const Uuid().v4();
                final newGroup = Group(
                  id: newGroupId,
                  administratorId: widget.member.id,
                  name: editedGroup.name,
                  memo: editedGroup.memo,
                );
                await _createGroupUsecase.execute(newGroup);

                // 選択されたメンバーをGroupMemberとして登録
                for (final memberId in selectedMemberIds) {
                  final groupMember = GroupMember(
                    id: const Uuid().v4(),
                    groupId: newGroupId,
                    memberId: memberId,
                  );
                  await _createGroupMemberUsecase.execute(groupMember);
                }
              } else {
                // TODO: グループ更新機能は後で実装
              }
              if (mounted) {
                await _loadData();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      group == null ? 'グループを作成しました' : 'グループを更新しました',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('操作に失敗しました: $e')),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('メンバー情報の取得に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('group_settings'),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.group_work, size: 32),
                      const SizedBox(width: 16),
                      const Text(
                        'グループ設定',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showGroupEditModal(),
                        icon: const Icon(Icons.add),
                        label: const Text('グループ追加'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _managedGroups.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_work,
                                size: 100,
                                color: Colors.grey,
                              ),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _managedGroups.length,
                            itemBuilder: (context, index) {
                              final group = _managedGroups[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(group.name.substring(0, 1)),
                                  ),
                                  title: Text(group.name),
                                  subtitle: group.memo != null
                                      ? Text(group.memo!)
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteGroup(group),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
