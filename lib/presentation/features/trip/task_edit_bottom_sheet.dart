import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';

class TaskEditBottomSheet extends HookWidget {
  const TaskEditBottomSheet({
    super.key,
    required this.task,
    required this.tasks,
    required this.groupMembers,
    required this.onSaved,
  });

  final TaskDto task;
  final List<TaskDto> tasks;
  final List<GroupMemberDto> groupMembers;
  final ValueChanged<TaskDto> onSaved;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: task.name);
    final memoController = useTextEditingController(text: task.memo ?? '');
    final dueDateState = useState<DateTime?>(task.dueDate);
    final assignedMemberState = useState<String?>(task.assignedMemberId);
    final parentTaskState = useState<String?>(task.parentTaskId);
    final errorMessage = useState<String?>(null);

    bool hasChildren(String taskId) {
      return tasks.any((t) => t.parentTaskId == taskId);
    }

    List<TaskDto> parentCandidates() {
      return tasks.where((candidate) {
        if (candidate.id == task.id) {
          return false;
        }
        if (candidate.parentTaskId != null &&
            candidate.id != task.parentTaskId) {
          return false;
        }
        return true;
      }).toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    Future<void> pickDueDate() async {
      final selected = await DatePickerHelper.showCustomDatePicker(
        context,
        initialDate: dueDateState.value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (selected != null) {
        dueDateState.value = selected;
      }
    }

    void save() {
      final trimmedName = nameController.text.trim();
      if (trimmedName.isEmpty) {
        errorMessage.value = 'タスク名を入力してください';
        return;
      }

      final parentTaskId = hasChildren(task.id)
          ? task.parentTaskId
          : parentTaskState.value;
      final updated = task.copyWith(
        name: trimmedName,
        memo: memoController.text.isEmpty ? null : memoController.text,
        dueDate: dueDateState.value,
        assignedMemberId: assignedMemberState.value,
        parentTaskId: parentTaskId,
      );
      onSaved(updated);
      Navigator.of(context).pop();
    }

    Widget buildErrorBanner() {
      if (errorMessage.value == null) {
        return const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          errorMessage.value!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            buildErrorBanner(),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'タスク名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key: const Key('assigned_member_dropdown'),
              initialValue: assignedMemberState.value,
              decoration: const InputDecoration(
                labelText: '担当者',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('未選択'),
                ),
                ...groupMembers.map(
                  (member) => DropdownMenuItem(
                    value: member.memberId,
                    child: Text(member.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                assignedMemberState.value = value;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key: const Key('parent_task_dropdown'),
              initialValue: parentTaskState.value,
              decoration: const InputDecoration(
                labelText: '親タスク',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('なし')),
                ...parentCandidates().map(
                  (candidate) => DropdownMenuItem<String?>(
                    value: candidate.id,
                    child: Text(candidate.name),
                  ),
                ),
              ],
              onChanged: hasChildren(task.id)
                  ? null
                  : (value) {
                      parentTaskState.value = value;
                    },
            ),
            if (hasChildren(task.id))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '子タスクがあるため親タスクは変更できません',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: pickDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '締切日',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        dueDateState.value != null
                            ? '${dueDateState.value!.year}/${dueDateState.value!.month.toString().padLeft(2, '0')}/${dueDateState.value!.day.toString().padLeft(2, '0')}'
                            : '選択してください',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => dueDateState.value = null,
                  tooltip: '締切日をクリア',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: memoController,
              decoration: const InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: save, child: const Text('保存')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
