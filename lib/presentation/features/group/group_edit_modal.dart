import 'package:flutter/material.dart';
import '../../../domain/entities/group.dart';
import '../../../domain/entities/member.dart';

class GroupEditModal extends StatefulWidget {
  final Group? group;
  final Function(Group, List<String>) onSave;
  final List<Member> availableMembers;
  final List<String>? selectedMemberIds;

  const GroupEditModal({
    super.key,
    this.group,
    required this.onSave,
    required this.availableMembers,
    this.selectedMemberIds,
  });

  @override
  State<GroupEditModal> createState() => _GroupEditModalState();
}

class _GroupEditModalState extends State<GroupEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _memoController;
  final List<String> _selectedMemberIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _memoController = TextEditingController(text: widget.group?.memo ?? '');

    final initialMemberIds =
        widget.selectedMemberIds ??
        widget.group?.members?.map((member) => member.memberId).toList();

    if (initialMemberIds != null) {
      _selectedMemberIds.addAll(initialMemberIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;

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
        if (_selectedMemberIds.isEmpty)
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
        itemCount: _selectedMemberIds.length,
        itemBuilder: (context, index) => _buildMemberListTile(index),
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }

  Widget _buildMemberListTile(int index) {
    final memberId = _selectedMemberIds[index];
    final member = _findMemberById(memberId);
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
        label: const Text('＋追加'),
        onPressed: addableMembers.isEmpty
            ? null
            : () => _showMemberSelectionMenu(buttonContext, addableMembers, (
                selectedMemberId,
              ) {
                setState(() {
                  _selectedMemberIds.add(selectedMemberId);
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
                  _selectedMemberIds[index] = selectedMemberId;
                });
              }),
      ),
    );
  }

  void _removeMemberAt(int index) {
    setState(() {
      _selectedMemberIds.removeAt(index);
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
    return widget.availableMembers
        .where((member) => !_selectedMemberIds.contains(member.id))
        .toList();
  }

  List<Member> _getChangeCandidates(int index) {
    final currentMemberId = _selectedMemberIds[index];

    return widget.availableMembers.where((member) {
      if (member.id == currentMemberId) {
        return true;
      }
      return !_selectedMemberIds.contains(member.id);
    }).toList();
  }

  Future<void> _showMemberSelectionMenu(
    BuildContext anchorContext,
    List<Member> candidates,
    ValueChanged<String> onSelected,
  ) async {
    final renderBox = anchorContext.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final overlayState = Overlay.of(context);
    final overlay = overlayState.context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      return;
    }

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selectedMemberId = await showMenu<String>(
      context: context,
      position: position,
      items: candidates
          .map(
            (member) => PopupMenuItem<String>(
              value: member.id,
              child: Text(member.displayName),
            ),
          )
          .toList(),
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
      final group = Group(
        id: widget.group?.id ?? '',
        ownerId: widget.group?.ownerId ?? '',
        name: _nameController.text,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
      );

      widget.onSave(group, List.of(_selectedMemberIds));
      Navigator.of(context).pop();
    }
  }
}
