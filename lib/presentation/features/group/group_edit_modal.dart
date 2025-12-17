import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/presentation/helpers/focus_killer.dart';

enum _MemberAction { toggleAdministrator, changeMember, removeMember }

class GroupEditModal extends HookWidget {
  final GroupDto group;
  final Function(Group) onSave;
  final List<GroupMemberDto> availableMembers;

  const GroupEditModal({
    super.key,
    required this.group,
    required this.onSave,
    required this.availableMembers,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: group.name);
    final memoController = useTextEditingController(text: group.memo ?? '');
    final groupState = useState<GroupDto>(group);
    final isEditing = group.id.isNotEmpty;

    GroupMemberDto? findMemberById(String memberId) {
      for (final member in availableMembers) {
        if (member.memberId == memberId) {
          return member;
        }
      }
      return null;
    }

    List<GroupMemberDto> getAddableMembers() {
      final selectedIds = groupState.value.members
          .map((gm) => gm.memberId)
          .toSet();
      return availableMembers
          .where((member) => !selectedIds.contains(member.memberId))
          .toList();
    }

    List<GroupMemberDto> getChangeCandidates(int index) {
      final currentMemberId = groupState.value.members[index].memberId;
      final selectedIds = groupState.value.members
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map((entry) => entry.value.memberId)
          .toSet();

      final candidates = <GroupMemberDto>[];
      final currentMember = findMemberById(currentMemberId);
      if (currentMember != null) {
        candidates.add(currentMember);
      }

      candidates.addAll(
        availableMembers.where((member) {
          if (member.memberId == currentMemberId) {
            return false;
          }
          return !selectedIds.contains(member.memberId);
        }),
      );

      return candidates;
    }

    void updateGroupMembers(List<GroupMemberDto> members) {
      groupState.value = groupState.value.copyWith(members: members);
    }

    void removeMemberAt(int index) {
      final updatedMembers = List<GroupMemberDto>.from(
        groupState.value.members,
      );
      updatedMembers.removeAt(index);
      updateGroupMembers(updatedMembers);
    }

    void toggleAdministrator(int index) {
      final updatedMembers = List<GroupMemberDto>.from(
        groupState.value.members,
      );
      updatedMembers[index] = updatedMembers[index].copyWith(
        isAdministrator: !updatedMembers[index].isAdministrator,
      );
      updateGroupMembers(updatedMembers);
    }

    Future<void> showMemberSelectionMenu(
      List<GroupMemberDto> candidates,
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

    void handleMemberAction(
      int index,
      _MemberAction action,
      List<GroupMemberDto> changeCandidates,
    ) {
      switch (action) {
        case _MemberAction.toggleAdministrator:
          toggleAdministrator(index);
          break;
        case _MemberAction.changeMember:
          final currentMemberId = groupState.value.members[index].memberId;
          final hasAlternative = changeCandidates
              .where((candidate) => candidate.memberId != currentMemberId)
              .isNotEmpty;

          if (!hasAlternative) {
            return;
          }

          showMemberSelectionMenu(changeCandidates, (selectedMemberId) {
            final selectedMember = findMemberById(selectedMemberId);
            if (selectedMember == null) {
              return;
            }
            final updatedMembers = List<GroupMemberDto>.from(
              groupState.value.members,
            );
            updatedMembers[index] = selectedMember;
            updateGroupMembers(updatedMembers);
          });
          break;
        case _MemberAction.removeMember:
          removeMemberAt(index);
          break;
      }
    }

    Widget buildTitle() {
      return Text(
        isEditing ? 'グループ編集' : 'グループ新規作成',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      );
    }

    Widget buildGroupNameField() {
      return TextFormField(
        controller: nameController,
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

    Widget buildMemoField() {
      return TextFormField(
        controller: memoController,
        decoration: const InputDecoration(
          labelText: 'メモ',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      );
    }

    Widget buildMemberActionMenu(
      int index,
      GroupMemberDto groupMember,
      List<GroupMemberDto> changeCandidates,
    ) {
      final hasAlternative = changeCandidates
          .where((candidate) => candidate.memberId != groupMember.memberId)
          .isNotEmpty;

      return PopupMenuButton<_MemberAction>(
        key: Key('member_action_menu_$index'),
        icon: const Icon(Icons.more_vert),
        tooltip: '操作メニュー',
        onOpened: () => FocusKiller.killFocus(),
        onSelected: (action) =>
            handleMemberAction(index, action, changeCandidates),
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

    Widget buildAdminBadge() {
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

    Widget buildAdminBadgeSlot(int index, bool isAdministrator) {
      const badgeSlotWidth = 72.0;
      return SizedBox(
        key: Key('admin_badge_slot_$index'),
        width: badgeSlotWidth,
        child: isAdministrator
            ? Align(alignment: Alignment.centerLeft, child: buildAdminBadge())
            : const SizedBox.shrink(),
      );
    }

    Widget buildMemberContainer(int index) {
      final groupMember = groupState.value.members[index];
      final member = findMemberById(groupMember.memberId);
      final displayName = groupMember.displayName.isNotEmpty
          ? groupMember.displayName
          : member?.displayName ?? '不明なメンバー';
      final changeCandidates = getChangeCandidates(index);

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
            buildAdminBadgeSlot(index, groupMember.isAdministrator),
            const SizedBox(width: 8),
            buildMemberActionMenu(index, groupMember, changeCandidates),
          ],
        ),
      );
    }

    Widget buildSelectedMemberList() {
      return SizedBox(
        key: const Key('selected_member_list'),
        height: 250,
        child: ListView.separated(
          itemCount: groupState.value.members.length,
          itemBuilder: (context, index) => buildMemberContainer(index),
          separatorBuilder: (context, index) => const Divider(height: 1),
        ),
      );
    }

    Widget buildEmptyMemberState() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'メンバーが追加されていません',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    Widget buildAddMemberButton() {
      final addableMembers = getAddableMembers();

      return Builder(
        builder: (buttonContext) => ElevatedButton.icon(
          key: const Key('add_member_button'),
          icon: const Icon(Icons.add),
          label: const Text('追加'),
          onPressed: addableMembers.isEmpty
              ? null
              : () {
                  FocusKiller.killFocus();
                  showMemberSelectionMenu(addableMembers, (selectedMemberId) {
                    final selectedMember = findMemberById(selectedMemberId);
                    if (selectedMember == null) {
                      return;
                    }
                    final updatedMembers = List<GroupMemberDto>.from(
                      groupState.value.members,
                    );
                    updatedMembers.add(selectedMember);
                    updateGroupMembers(updatedMembers);
                  });
                },
        ),
      );
    }

    Widget buildMemberManagementSection() {
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
          if (groupState.value.members.isEmpty)
            buildEmptyMemberState()
          else
            buildSelectedMemberList(),
          const SizedBox(height: 12),
          buildAddMemberButton(),
        ],
      );
    }

    Widget buildScrollableContent() {
      return SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildGroupNameField(),
              const SizedBox(height: 16),
              buildMemoField(),
              const SizedBox(height: 16),
              buildMemberManagementSection(),
            ],
          ),
        ),
      );
    }

    Widget buildActionButtons() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedGroup = groupState.value.copyWith(
                  name: nameController.text,
                  memo: memoController.text.isEmpty
                      ? null
                      : memoController.text,
                );
                onSave(GroupMapper.toEntity(updatedGroup));
                Navigator.of(context).pop();
              }
            },
            child: Text(isEditing ? '更新' : '作成'),
          ),
        ],
      );
    }

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
                  buildTitle(),
                  const SizedBox(height: 20),
                  Expanded(child: buildScrollableContent()),
                  const SizedBox(height: 24),
                  buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    List<GroupMemberDto> candidates,
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
            onTap: () => Navigator.of(context).pop(member.memberId),
            hoverColor: Colors.grey[50],
          ),
        );
      },
    );
  }
}
