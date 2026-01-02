import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:uuid/uuid.dart';

class EditableTask {
  const EditableTask({required this.id, required this.task});

  final String id;
  final Task task;

  EditableTask copyWith({String? id, Task? task}) {
    return EditableTask(id: id ?? this.id, task: task ?? this.task);
  }
}

class TaskViewTestHandle {
  List<EditableTask> Function()? _getTasks;
  void Function(int oldIndex, int newIndex)? _reorder;

  List<EditableTask> get tasks => _getTasks?.call() ?? const [];

  void reorderForTest(int oldIndex, int newIndex) {
    _reorder?.call(oldIndex, newIndex);
  }
}

class TaskView extends HookConsumerWidget {
  const TaskView({
    super.key,
    required this.tripId,
    required this.tasks,
    required this.onChanged,
    required this.onClose,
    this.assignableMembers = const [],
    this.testHandle,
  });

  final String tripId;
  final List<EditableTask> tasks;
  final List<GroupMemberDto> assignableMembers;
  final ValueChanged<List<EditableTask>> onChanged;
  final VoidCallback onClose;
  final TaskViewTestHandle? testHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialTasks = useMemoized(() {
      final sorted = [...tasks]
        ..sort((a, b) => a.task.orderIndex.compareTo(b.task.orderIndex));
      return _reindexTasks(sorted);
    }, [tasks]);
    final tasksState = useState<List<EditableTask>>(initialTasks);
    final memberNameMap = useMemoized(
      () => {
        for (final member in assignableMembers)
          member.memberId: member.displayName,
      },
      [assignableMembers],
    );
    final parentTaskMap = useMemoized(
      () => {for (final task in tasksState.value) task.id: task},
      [tasksState.value],
    );

    void publish(List<EditableTask> updated) {
      final next = _reindexTasks(updated);
      tasksState.value = next;
      onChanged(next);
    }

    void toggleCompletion(String taskId, bool? value) {
      final updated = tasksState.value.map((editable) {
        if (editable.id != taskId) {
          return editable;
        }
        return editable.copyWith(
          task: editable.task.copyWith(isCompleted: value ?? false),
        );
      }).toList();
      publish(updated);
    }

    void deleteTask(String taskId) {
      final updated = tasksState.value
          .where((editable) => editable.id != taskId)
          .toList();
      publish(updated);
    }

    Future<void> showTaskForm({EditableTask? initialTask}) async {
      final result = await showModalBottomSheet<EditableTask>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return _TaskFormSheet(
            tripId: tripId,
            initialTask: initialTask,
            parentCandidates: tasksState.value,
            assignableMembers: assignableMembers,
            onSubmit: Navigator.of(sheetContext).pop,
          );
        },
      );

      if (result == null) {
        return;
      }

      if (initialTask == null) {
        publish([...tasksState.value, result]);
        return;
      }

      final updated = tasksState.value.map((editable) {
        if (editable.id == result.id) {
          return result;
        }
        return editable;
      }).toList();
      publish(updated);
    }

    void onReorder(int oldIndex, int newIndex) {
      var targetNewIndex = newIndex;
      if (targetNewIndex > oldIndex) {
        targetNewIndex -= 1;
      }
      final updated = List<EditableTask>.from(tasksState.value);
      final item = updated.removeAt(oldIndex);
      updated.insert(targetNewIndex, item);
      publish(updated);
    }

    useEffect(() {
      if (testHandle != null) {
        testHandle!._getTasks = () => List.unmodifiable(tasksState.value);
        testHandle!._reorder = onReorder;
      }
      return null;
    }, [testHandle]);

    Widget buildHeader() {
      return Row(
        children: [
          const Text(
            'タスク管理',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      );
    }

    Widget buildActions() {
      return Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => showTaskForm(),
            icon: const Icon(Icons.add),
            label: const Text('タスク追加'),
          ),
        ],
      );
    }

    Widget buildEmpty() {
      return const Center(
        child: Text(
          'タスクがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    Widget buildTaskTile(EditableTask editable, int index) {
      final task = editable.task;
      final memoLabel = task.memo != null && task.memo!.isNotEmpty
          ? 'メモあり'
          : null;
      final assignedName = task.assignedMemberId != null
          ? memberNameMap[task.assignedMemberId]
          : null;
      final parentLabel = task.parentTaskId != null
          ? (parentTaskMap[task.parentTaskId]?.task.name ?? '(削除済み)')
          : null;

      return Card(
        key: ValueKey(editable.id),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          title: Row(
            children: [
              Checkbox(
                key: Key('task_complete_checkbox_${editable.id}'),
                value: task.isCompleted,
                onChanged: (value) => toggleCompletion(editable.id, value),
              ),
              Expanded(
                child: Text(
                  task.name,
                  style: TextStyle(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.dueDate != null)
                Text('締切: ${_formatDueDate(task.dueDate!)}'),
              if (assignedName != null) Text('担当: $assignedName'),
              if (parentLabel != null) Text('親タスク: $parentLabel'),
              if (memoLabel != null) Text(memoLabel),
            ],
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showTaskForm(initialTask: editable),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteTask(editable.id),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildTaskList() {
      return ReorderableListView.builder(
        key: const Key('task_reorderable_list'),
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: tasksState.value.length,
        onReorder: onReorder,
        itemBuilder: (context, index) {
          final editable = tasksState.value[index];
          return buildTaskTile(editable, index);
        },
      );
    }

    return Column(
      key: const Key('task_view_root'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        buildActions(),
        const SizedBox(height: 12),
        Expanded(
          child: tasksState.value.isEmpty ? buildEmpty() : buildTaskList(),
        ),
      ],
    );
  }
}

class _TaskFormSheet extends HookWidget {
  const _TaskFormSheet({
    required this.tripId,
    required this.parentCandidates,
    required this.assignableMembers,
    required this.onSubmit,
    this.initialTask,
  });

  final String tripId;
  final EditableTask? initialTask;
  final List<EditableTask> parentCandidates;
  final List<GroupMemberDto> assignableMembers;
  final ValueChanged<EditableTask> onSubmit;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(
      text: initialTask?.task.name ?? '',
    );
    final memoController = useTextEditingController(
      text: initialTask?.task.memo ?? '',
    );
    final dueDateController = useTextEditingController(
      text: initialTask?.task.dueDate != null
          ? _formatDueDate(initialTask!.task.dueDate!)
          : '',
    );
    final isCompleted = useState<bool>(initialTask?.task.isCompleted ?? false);
    final selectedParentId = useState<String?>(initialTask?.task.parentTaskId);
    final selectedMemberId = useState<String?>(
      initialTask?.task.assignedMemberId,
    );
    final errorMessage = useState<String?>(null);

    final parentOptions = parentCandidates
        .where((candidate) => candidate.id != initialTask?.id)
        .toList();

    DateTime? parseDueDate(String text) {
      final normalized = text.trim();
      if (normalized.isEmpty) {
        return null;
      }
      var candidate = normalized.replaceAll('/', '-');
      final parts = candidate.split(' ');
      if (parts.length == 2) {
        final timePart = parts[1];
        final hhMmPattern = RegExp(r'^\d{1,2}:\d{2}$');
        if (hhMmPattern.hasMatch(timePart)) {
          candidate = '${parts[0]} $timePart:00';
        }
      }
      return DateTime.tryParse(candidate);
    }

    void handleSubmit() {
      errorMessage.value = null;
      final dueDateText = dueDateController.text.trim();
      final dueDate = parseDueDate(dueDateText);
      if (dueDateText.isNotEmpty && dueDate == null) {
        errorMessage.value = '締切日時の形式が正しくありません (例: 2024/05/20 10:00)';
        return;
      }

      try {
        final task = Task(
          tripId: tripId,
          orderIndex: initialTask?.task.orderIndex ?? parentCandidates.length,
          parentTaskId: selectedParentId.value,
          name: nameController.text,
          isCompleted: isCompleted.value,
          dueDate: dueDate,
          memo: memoController.text.isEmpty ? null : memoController.text,
          assignedMemberId: selectedMemberId.value,
        );
        final editable = EditableTask(
          id: initialTask?.id ?? const Uuid().v4(),
          task: task,
        );
        onSubmit(editable);
      } on ValidationException catch (e) {
        errorMessage.value = '$e';
      }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'タスク編集',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (errorMessage.value != null) ...[
              Container(
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
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              key: const Key('task_name_field'),
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'タスク名*',
                border: OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('完了'),
              value: isCompleted.value,
              onChanged: (value) => isCompleted.value = value ?? false,
            ),
            DropdownButtonFormField<String?>(
              initialValue: selectedParentId.value,
              decoration: const InputDecoration(
                labelText: '親タスク',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('未設定'),
                ),
                ...parentOptions.map(
                  (task) => DropdownMenuItem<String?>(
                    value: task.id,
                    child: Text(task.task.name),
                  ),
                ),
              ],
              onChanged: (value) => selectedParentId.value = value,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: selectedMemberId.value,
              decoration: const InputDecoration(
                labelText: '担当メンバー',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('未設定'),
                ),
                ...assignableMembers.map(
                  (member) => DropdownMenuItem<String?>(
                    value: member.memberId,
                    child: Text(member.displayName),
                  ),
                ),
              ],
              onChanged: (value) => selectedMemberId.value = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dueDateController,
              decoration: const InputDecoration(
                labelText: '締切日時 (例: 2024/05/20 10:00)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('閉じる'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: handleSubmit,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDueDate(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$year/$month/$day $hour:$minute';
}

List<EditableTask> _reindexTasks(List<EditableTask> tasks) {
  return [
    for (var i = 0; i < tasks.length; i++)
      tasks[i].copyWith(task: tasks[i].task.copyWith(orderIndex: i)),
  ];
}
