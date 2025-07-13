import 'package:flutter/material.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/member.dart';

class GroupEditModal extends StatefulWidget {
  final Group? group;
  final Function(Group, List<String>) onSave;
  final List<Member> availableMembers;

  const GroupEditModal({
    super.key,
    this.group,
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
  final Set<String> _selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _memoController = TextEditingController(text: widget.group?.memo ?? '');
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
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'グループ編集' : 'グループ新規作成',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          labelText: 'メモ',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      if (widget.availableMembers.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'メンバー選択',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          key: const Key('member_list_container'),
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            itemCount: widget.availableMembers.length,
                            itemBuilder: (context, index) {
                              final member = widget.availableMembers[index];
                              return CheckboxListTile(
                                title: Text(member.displayName),
                                subtitle:
                                    member.email != null ||
                                        member.phoneNumber != null
                                    ? Text(
                                        member.email ??
                                            member.phoneNumber ??
                                            '',
                                      )
                                    : null,
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
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final group = Group(
                        id: widget.group?.id ?? '',
                        administratorId: widget.group?.administratorId ?? '',
                        name: _nameController.text,
                        memo: _memoController.text.isEmpty
                            ? null
                            : _memoController.text,
                      );

                      widget.onSave(group, _selectedMemberIds.toList());
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(isEditing ? '更新' : '作成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
