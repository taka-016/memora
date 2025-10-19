import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group_mapper.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/helpers/focus_killer.dart';

class GroupEditModal extends StatefulWidget {
  final GroupDto group;
  final Function(Group) onSave;
  final List<Member> availableMembers;

  const GroupEditModal({
    super.key,
    required this.group,
    required this.onSave,
    required this.availableMembers,
  });

  @override
  State<GroupEditModal> createState() => _GroupEditModalState();
}

enum _MemberAction { toggleAdministrator, changeMember, removeMember }

class _GroupEditModalState extends State<GroupEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _memoController;
  late GroupDto _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _nameController = TextEditingController(text: _group.name);
    _memoController = TextEditingController(text: _group.memo ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group.id.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Material(
        type: MaterialType.card,
        child: Stack(
          children: [
            FocusKiller.createDummyFocusWidget(),
            Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(isEditing),
                  const SizedBox(height: 20),
                  Expanded(child: _buildScrollableContent()),
                  const SizedBox(height: 24),
                  _buildActionButtons(isEditing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(bool isEditing) {
    return Text(
      isEditing ? 'グループ編集' : 'グループ新規作成',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGroupNameField(),
            const SizedBox(height: 16),
            _buildMemoField(),
            const SizedBox(height: 16),
            _buildMemberManagementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'グループ名',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'グループ名を入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildMemoField() {
    return TextFormField(
      controller: _memoController,
      decoration: const InputDecoration(
        labelText: 'メモ',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildMemberManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'メンバー一覧',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        if (_group.members.isEmpty)
          _buildEmptyMemberState()
        else
          _buildSelectedMemberList(),
        const SizedBox(height: 12),
        _buildAddMemberButton(),
      ],
    );
  }

  Widget _buildEmptyMemberState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('メンバーが追加されていません', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildSelectedMemberList() {
    return SizedBox(
      key: const Key('selected_member_list'),
      height: 250,
      child: ListView.separated(
        itemCount: _group.members.length,
        itemBuilder: (context, index) => _buildMemberContainer(index),
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }

  Widget _buildMemberContainer(int index) {
    final groupMember = _group.members[index];
    final member = _findMemberById(groupMember.memberId);
    final displayName = groupMember.displayName.isNotEmpty
        ? groupMember.displayName
        : member?.displayName ?? '不明なメンバー';
    final changeCandidates = _getChangeCandidates(index);

    return Container(
      key: Key('member_row_$index'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _buildAdminBadgeSlot(index, groupMember.isAdministrator),
          const SizedBox(width: 8),
          _buildMemberActionMenu(index, groupMember, changeCandidates),
        ],
      ),
    );
  }

  Widget _buildMemberActionMenu(
    int index,
    GroupMemberDto groupMember,
    List<Member> changeCandidates,
  ) {
    final hasAlternative = changeCandidates
        .where((candidate) => candidate.id != groupMember.memberId)
        .isNotEmpty;

    return PopupMenuButton<_MemberAction>(
      key: Key('member_action_menu_$index'),
      icon: const Icon(Icons.more_vert),
      tooltip: '操作メニュー',
      onOpened: () => FocusKiller.killFocus(),
      onSelected: (action) =>
          _handleMemberAction(index, action, changeCandidates),
      itemBuilder: (context) => [
        PopupMenuItem<_MemberAction>(
          key: Key('member_toggle_admin_action_$index'),
          value: _MemberAction.toggleAdministrator,
          child: Text(groupMember.isAdministrator ? '管理者を解除' : '管理者に設定'),
        ),
        PopupMenuItem<_MemberAction>(
          key: Key('member_change_action_$index'),
          value: _MemberAction.changeMember,
          enabled: hasAlternative,
          child: const Text('メンバーを変更'),
        ),
        const PopupMenuItem<_MemberAction>(
          value: _MemberAction.removeMember,
          child: Text('メンバーを削除'),
        ),
      ],
    );
  }

  Widget _buildAddMemberButton() {
    final addableMembers = _getAddableMembers();

    return Builder(
      builder: (buttonContext) => ElevatedButton.icon(
        key: const Key('add_member_button'),
        icon: const Icon(Icons.add),
        label: const Text('追加'),
        onPressed: addableMembers.isEmpty
            ? null
            : () {
                FocusKiller.killFocus();
                _showMemberSelectionMenu(addableMembers, (selectedMemberId) {
                  setState(() {
                    final selectedMember = _findMemberById(selectedMemberId);
                    final updatedMembers = List<GroupMemberDto>.from(
                      _group.members,
                    );
                    if (selectedMember != null) {
                      updatedMembers.add(_createGroupMemberDto(selectedMember));
                    }
                    _group = _group.copyWith(members: updatedMembers);
                  });
                });
              },
      ),
    );
  }

  void _removeMemberAt(int index) {
    setState(() {
      final updatedMembers = List<GroupMemberDto>.from(_group.members);
      updatedMembers.removeAt(index);
      _group = _group.copyWith(members: updatedMembers);
    });
  }

  void _handleMemberAction(
    int index,
    _MemberAction action,
    List<Member> changeCandidates,
  ) {
    switch (action) {
      case _MemberAction.toggleAdministrator:
        _toggleAdministrator(index);
        break;
      case _MemberAction.changeMember:
        final currentMemberId = _group.members[index].memberId;
        final hasAlternative = changeCandidates
            .where((candidate) => candidate.id != currentMemberId)
            .isNotEmpty;

        if (!hasAlternative) {
          return;
        }
        _showMemberSelectionMenu(changeCandidates, (selectedMemberId) {
          setState(() {
            final selectedMember = _findMemberById(selectedMemberId);
            final updatedMembers = List<GroupMemberDto>.from(_group.members);
            if (selectedMember != null) {
              updatedMembers[index] = _createGroupMemberDto(
                selectedMember,
                existing: updatedMembers[index],
              );
            }
            _group = _group.copyWith(members: updatedMembers);
          });
        });
        break;
      case _MemberAction.removeMember:
        _removeMemberAt(index);
        break;
    }
  }

  void _toggleAdministrator(int index) {
    setState(() {
      final updatedMembers = List<GroupMemberDto>.from(_group.members);
      updatedMembers[index] = updatedMembers[index].copyWith(
        isAdministrator: !updatedMembers[index].isAdministrator,
      );
      _group = _group.copyWith(members: updatedMembers);
    });
  }

  Widget _buildAdminBadgeSlot(int index, bool isAdministrator) {
    const badgeSlotWidth = 72.0;
    return SizedBox(
      key: Key('admin_badge_slot_$index'),
      width: badgeSlotWidth,
      child: isAdministrator
          ? Align(alignment: Alignment.centerLeft, child: _buildAdminBadge())
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '管理者',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Member? _findMemberById(String memberId) {
    for (final member in widget.availableMembers) {
      if (member.id == memberId) {
        return member;
      }
    }
    return null;
  }

  List<Member> _getAddableMembers() {
    final selectedMemberIds = _group.members.map((gm) => gm.memberId).toSet();
    return widget.availableMembers
        .where((member) => !selectedMemberIds.contains(member.id))
        .toList();
  }

  List<Member> _getChangeCandidates(int index) {
    final currentMemberId = _group.members[index].memberId;
    final selectedMemberIds = _group.members
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value.memberId)
        .toSet();

    final candidates = <Member>[];
    final currentMember = _findMemberById(currentMemberId);
    if (currentMember != null) {
      candidates.add(currentMember);
    }

    candidates.addAll(
      widget.availableMembers.where((member) {
        if (member.id == currentMemberId) {
          return false;
        }
        return !selectedMemberIds.contains(member.id);
      }),
    );

    return candidates;
  }

  Future<void> _showMemberSelectionMenu(
    List<Member> candidates,
    ValueChanged<String> onSelected,
  ) async {
    final selectedMemberId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              _buildMemberSelectionModalHandle(),
              _buildMemberSelectionModalHeader(context),
              const Divider(height: 1),
              Expanded(
                child: candidates.isEmpty
                    ? _buildMemberSelectionEmptyState()
                    : _buildMemberSelectionList(candidates, scrollController),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (selectedMemberId != null) {
      onSelected(selectedMemberId);
    }
  }

  Widget _buildActionButtons(bool isEditing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildCancelButton(),
        const SizedBox(width: 8),
        _buildSaveButton(isEditing),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('キャンセル'),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return ElevatedButton(
      onPressed: _handleSave,
      child: Text(isEditing ? '更新' : '作成'),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final updatedGroup = _group.copyWith(
        name: _nameController.text,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
      );

      widget.onSave(GroupMapper.toEntity(updatedGroup));
      Navigator.of(context).pop();
    }
  }

  Widget _buildMemberSelectionModalHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMemberSelectionModalHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'メンバーを選択',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSelectionEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            '選択可能なメンバーがいません',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSelectionList(
    List<Member> candidates,
    ScrollController scrollController,
  ) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final member = candidates[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              member.displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () => Navigator.of(context).pop(member.id),
            hoverColor: Colors.grey[50],
          ),
        );
      },
    );
  }

  GroupMemberDto _createGroupMemberDto(
    Member member, {
    GroupMemberDto? existing,
  }) {
    final groupId = existing?.groupId.isNotEmpty == true
        ? existing!.groupId
        : _group.id;

    return GroupMemberDto(
      memberId: member.id,
      groupId: groupId,
      isAdministrator: existing?.isAdministrator ?? false,
      accountId: member.accountId,
      ownerId: member.ownerId,
      hiraganaFirstName: member.hiraganaFirstName,
      hiraganaLastName: member.hiraganaLastName,
      kanjiFirstName: member.kanjiFirstName,
      kanjiLastName: member.kanjiLastName,
      firstName: member.firstName,
      lastName: member.lastName,
      displayName: member.displayName,
      type: member.type,
      birthday: member.birthday,
      gender: member.gender,
      email: member.email,
      phoneNumber: member.phoneNumber,
      passportNumber: member.passportNumber,
      passportExpiration: member.passportExpiration,
    );
  }
}
