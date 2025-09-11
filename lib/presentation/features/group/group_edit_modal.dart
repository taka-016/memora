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
  final Set<String> _selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _memoController = TextEditingController(text: widget.group?.memo ?? '');

    if (widget.selectedMemberIds != null) {
      _selectedMemberIds.addAll(widget.selectedMemberIds!);
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
            if (widget.availableMembers.isNotEmpty) _buildMemberSelection(),
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

  Widget _buildMemberSelection() {
    return Column(
      children: [
        _buildMemberSelectionHeader(),
        const SizedBox(height: 8),
        _buildMemberList(),
      ],
    );
  }

  Widget _buildMemberSelectionHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'メンバー選択',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildMemberList() {
    return SizedBox(
      key: const Key('member_list_container'),
      height: 350,
      child: ListView.builder(
        itemCount: widget.availableMembers.length,
        itemBuilder: (context, index) => _buildMemberCheckbox(index),
      ),
    );
  }

  Widget _buildMemberCheckbox(int index) {
    final member = widget.availableMembers[index];
    return CheckboxListTile(
      title: Text(member.displayName),
      value: _selectedMemberIds.contains(member.id),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedMemberIds.add(member.id);
          } else {
            _selectedMemberIds.remove(member.id);
          }
        });
      },
    );
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

      widget.onSave(group, _selectedMemberIds.toList());
      Navigator.of(context).pop();
    }
  }
}
