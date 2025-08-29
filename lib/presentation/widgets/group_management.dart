import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'components/delete_confirm_dialog.dart';
import '../../application/usecases/get_managed_groups_with_members_usecase.dart';
import '../../application/usecases/delete_group_usecase.dart';
import '../../application/usecases/create_group_usecase.dart';
import '../../application/usecases/update_group_usecase.dart';
import '../../application/usecases/get_managed_members_usecase.dart';
import '../../application/usecases/create_group_member_usecase.dart';
import '../../application/usecases/delete_group_members_by_group_id_usecase.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/repositories/group_member_repository.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../../domain/repositories/trip_entry_repository.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/repositories/trip_participant_repository.dart';
import '../../infrastructure/repositories/firestore_group_repository.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import '../../infrastructure/repositories/firestore_group_member_repository.dart';
import '../../infrastructure/repositories/firestore_group_event_repository.dart';
import '../../infrastructure/repositories/firestore_trip_entry_repository.dart';
import '../../infrastructure/repositories/firestore_pin_repository.dart';
import '../../infrastructure/repositories/firestore_trip_participant_repository.dart';
import 'group_edit_modal.dart';

class GroupManagement extends StatefulWidget {
  final Member member;
  final GroupRepository? groupRepository;
  final MemberRepository? memberRepository;
  final GroupMemberRepository? groupMemberRepository;
  final GroupEventRepository? groupEventRepository;
  final TripEntryRepository? tripEntryRepository;
  final PinRepository? pinRepository;
  final TripParticipantRepository? tripParticipantRepository;

  const GroupManagement({
    super.key,
    required this.member,
    this.groupRepository,
    this.memberRepository,
    this.groupMemberRepository,
    this.groupEventRepository,
    this.tripEntryRepository,
    this.pinRepository,
    this.tripParticipantRepository,
  });

  @override
  State<GroupManagement> createState() => _GroupManagementState();
}

class _GroupManagementState extends State<GroupManagement> {
  late final GetManagedGroupsWithMembersUsecase
  _getManagedGroupsWithMembersUsecase;
  late final DeleteGroupUsecase _deleteGroupUsecase;
  late final CreateGroupUsecase _createGroupUsecase;
  late final UpdateGroupUsecase _updateGroupUsecase;
  late final GetManagedMembersUsecase _getManagedMembersUsecase;
  late final CreateGroupMemberUsecase _createGroupMemberUsecase;
  late final DeleteGroupMembersByGroupIdUsecase
  _deleteGroupMembersByGroupIdUsecase;

  List<ManagedGroupWithMembers> _managedGroupsWithMembers = [];
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
    final groupEventRepository =
        widget.groupEventRepository ?? FirestoreGroupEventRepository();
    final tripEntryRepository =
        widget.tripEntryRepository ?? FirestoreTripEntryRepository();
    final pinRepository = widget.pinRepository ?? FirestorePinRepository();
    final tripParticipantRepository =
        widget.tripParticipantRepository ??
        FirestoreTripParticipantRepository();

    _getManagedGroupsWithMembersUsecase = GetManagedGroupsWithMembersUsecase(
      groupRepository,
      groupMemberRepository,
      memberRepository,
    );
    _deleteGroupUsecase = DeleteGroupUsecase(
      groupRepository,
      groupMemberRepository,
      groupEventRepository,
      tripEntryRepository,
      pinRepository,
      tripParticipantRepository,
    );
    _createGroupUsecase = CreateGroupUsecase(groupRepository);
    _updateGroupUsecase = UpdateGroupUsecase(groupRepository);
    _getManagedMembersUsecase = GetManagedMembersUsecase(memberRepository);
    _createGroupMemberUsecase = CreateGroupMemberUsecase(groupMemberRepository);
    _deleteGroupMembersByGroupIdUsecase = DeleteGroupMembersByGroupIdUsecase(
      groupMemberRepository,
    );

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final managedGroupsWithMembers = await _getManagedGroupsWithMembersUsecase
          .execute(widget.member);
      _managedGroupsWithMembers = managedGroupsWithMembers;
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

  Future<void> _showAddGroupDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final availableMembers = await _getManagedMembersUsecase.execute(
        widget.member,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => GroupEditModal(
          availableMembers: availableMembers,
          selectedMemberIds: null,
          onSave: (group, selectedMemberIds) async {
            try {
              final newGroup = Group(
                id: '', // IDは自動採番されるため空文字列
                administratorId: widget.member.id,
                name: group.name,
                memo: group.memo,
              );
              final newGroupId = await _createGroupUsecase.execute(newGroup);

              for (final memberId in selectedMemberIds) {
                final groupMember = GroupMember(
                  id: const Uuid().v4(),
                  groupId: newGroupId,
                  memberId: memberId,
                );
                await _createGroupMemberUsecase.execute(groupMember);
              }

              if (mounted) {
                await _loadData();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('グループを作成しました')),
                );
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('作成に失敗しました: $e')),
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

  Future<void> _showEditGroupDialog(Group group) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final availableMembers = await _getManagedMembersUsecase.execute(
        widget.member,
      );
      final groupWithMembers = _managedGroupsWithMembers.firstWhere(
        (gwm) => gwm.group.id == group.id,
      );
      final existingMemberIds = groupWithMembers.members
          .map((member) => member.id)
          .toList();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => GroupEditModal(
          group: group,
          availableMembers: availableMembers,
          selectedMemberIds: existingMemberIds,
          onSave: (editedGroup, selectedMemberIds) async {
            try {
              await _updateGroupUsecase.execute(editedGroup);
              await _deleteGroupMembersByGroupIdUsecase.execute(group.id);
              for (final memberId in selectedMemberIds) {
                final groupMember = GroupMember(
                  id: const Uuid().v4(),
                  groupId: group.id,
                  memberId: memberId,
                );
                await _createGroupMemberUsecase.execute(groupMember);
              }

              if (mounted) {
                await _loadData();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('グループを更新しました')),
                );
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('更新に失敗しました: $e')),
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

  Future<void> _showDeleteConfirmDialog(Group group) async {
    await DeleteConfirmDialog.show(
      context,
      title: 'グループ削除',
      content: '${group.name}を削除しますか？',
      onConfirm: () => _deleteGroup(group),
    );
  }

  Future<void> _deleteGroup(Group group) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('group_settings'),
      child: _isLoading ? _buildLoadingState() : _buildGroupManagementContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildGroupManagementContent() {
    return Column(
      children: [
        _buildHeader(),
        const Divider(),
        Expanded(child: _buildGroupListContent()),
      ],
    );
  }

  Widget _buildHeader() {
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
          _buildAddGroupButton(),
        ],
      ),
    );
  }

  Widget _buildAddGroupButton() {
    return ElevatedButton.icon(
      onPressed: _showAddGroupDialog,
      icon: const Icon(Icons.add),
      label: const Text('グループ追加'),
    );
  }

  Widget _buildGroupListContent() {
    return _managedGroupsWithMembers.isEmpty
        ? _buildEmptyState()
        : _buildGroupList();
  }

  Widget _buildEmptyState() {
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

  Widget _buildGroupList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _managedGroupsWithMembers.length,
        itemBuilder: (context, index) => _buildGroupCard(index),
      ),
    );
  }

  Widget _buildGroupCard(int index) {
    final groupWithMembers = _managedGroupsWithMembers[index];
    final group = groupWithMembers.group;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(group.name.substring(0, 1))),
        title: Text(group.name),
        subtitle: group.memo != null ? Text(group.memo!) : null,
        trailing: _buildDeleteButton(group),
        onTap: () => _showEditGroupDialog(group),
      ),
    );
  }

  Widget _buildDeleteButton(Group group) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () => _showDeleteConfirmDialog(group),
    );
  }
}
