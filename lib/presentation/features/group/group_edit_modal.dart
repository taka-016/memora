import 'package:flutter/material.dart';
import '../../../domain/entities/group.dart';
import '../../../domain/entities/group_member.dart';
import '../../../domain/entities/member.dart';

class GroupEditModal extends StatefulWidget {
  final Group group;
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

class _GroupEditModalState extends State<GroupEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _memoController;
  late Group _group;

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
        child: Container(
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
        itemBuilder: (context, index) => _buildMemberListTile(index),
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }

  Widget _buildMemberListTile(int index) {
    final groupMember = _group.members[index];
    final member = _findMemberById(groupMember.memberId);
    final displayName = member?.displayName ?? '不明なメンバー';

    return ListTile(
      key: Key('member_row_$index'),
      title: Text(displayName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChangeMemberButton(index),
          IconButton(
            key: Key('delete_member_button_$index'),
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeMemberAt(index),
          ),
        ],
      ),
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
            : () => _showMemberSelectionMenu(buttonContext, addableMembers, (
                selectedMemberId,
              ) {
                setState(() {
                  final updatedMembers = List<GroupMember>.from(_group.members);
                  updatedMembers.add(
                    GroupMember(groupId: _group.id, memberId: selectedMemberId),
                  );
                  _group = _group.copyWith(members: updatedMembers);
                });
              }),
      ),
    );
  }

  Widget _buildChangeMemberButton(int index) {
    final changeCandidates = _getChangeCandidates(index);

    return Builder(
      builder: (buttonContext) => IconButton(
        key: Key('change_member_button_$index'),
        icon: const Icon(Icons.edit),
        tooltip: 'メンバーを変更',
        onPressed: changeCandidates.isEmpty
            ? null
            : () => _showMemberSelectionMenu(buttonContext, changeCandidates, (
                selectedMemberId,
              ) {
                setState(() {
                  final updatedMembers = List<GroupMember>.from(_group.members);
                  updatedMembers[index] = GroupMember(
                    groupId: _group.id,
                    memberId: selectedMemberId,
                  );
                  _group = _group.copyWith(members: updatedMembers);
                });
              }),
      ),
    );
  }

  void _removeMemberAt(int index) {
    setState(() {
      final updatedMembers = List<GroupMember>.from(_group.members);
      updatedMembers.removeAt(index);
      _group = _group.copyWith(members: updatedMembers);
    });
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
    final selectedMemberIds = _group.members.map((gm) => gm.memberId).toSet();

    return widget.availableMembers.where((member) {
      if (member.id == currentMemberId) {
        return true;
      }
      return !selectedMemberIds.contains(member.id);
    }).toList();
  }

  Future<void> _showMemberSelectionMenu(
    BuildContext anchorContext,
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

    _handleMemberSelectionResult(selectedMemberId, onSelected);
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

      widget.onSave(updatedGroup);
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

  void _handleMemberSelectionResult(
    String? selectedMemberId,
    ValueChanged<String> onSelected,
  ) {
    if (selectedMemberId != null) {
      onSelected(selectedMemberId);
    }
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).unfocus();
        }
      });
    }
  }
}
